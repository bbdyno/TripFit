import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  arrayUnion,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  increment,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const projectId = 'demo-tripfit';
const roomId = 'room-main';
const otherRoomId = 'room-other';
const ownerId = 'owner';
const memberId = 'member';
const outsiderId = 'outsider';
const validHash = 'a'.repeat(64);
const expiredHash = 'b'.repeat(64);
const revokedHash = 'c'.repeat(64);
const wrongRoomHash = 'd'.repeat(64);
let testEnv;

function roomData(owner = ownerId, memberUids = [ownerId, memberId]) {
  return {
    ownerUid: owner,
    memberUids,
    memberCount: memberUids.length,
    title: 'Tokyo Together',
    destination: 'Tokyo',
    countryCode: 'JP',
    timezoneID: 'Asia/Tokyo',
    candidateStartDay: '2026-09-01',
    candidateEndDay: '2026-09-10',
    candidateDayCount: 10,
    durationDays: 3,
    stage: 'coordinating',
    confirmedStartDay: null,
    confirmedEndDay: null,
    updatedAt: Timestamp.now(),
    revision: 0,
    schemaVersion: 1,
  };
}

function memberData(uid, role = 'member', inviteHash = undefined) {
  const value = {
    uid,
    displayName: uid,
    role,
    isRequired: false,
    joinedAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
    schemaVersion: 1,
  };
  if (inviteHash) value.inviteHash = inviteHash;
  return value;
}

function availabilityData(uid) {
  return {
    ownerUid: uid,
    days: [{ day: '2026-09-01', status: 'available', slots: {}, source: 'manual' }],
    dayCount: 1,
    firstDay: '2026-09-01',
    lastDay: '2026-09-01',
    statusValues: ['available'],
    leaveUnits: 0,
    lateJoin: false,
    earlyLeave: false,
    note: null,
    updatedAt: serverTimestamp(),
    revision: 0,
    schemaVersion: 1,
  };
}

function packingData(assigneeUid = null) {
  return {
    roomId,
    title: 'Portable charger',
    category: 'electronics',
    quantity: 1,
    assigneeUid,
    isPacked: false,
    createdByUid: ownerId,
    updatedAt: Timestamp.now(),
    revision: 0,
    schemaVersion: 1,
  };
}

function lookPlanData(uid) {
  return {
    roomId,
    ownerUid: uid,
    day: '2026-09-01',
    outfitName: 'Rainy city walk',
    categories: ['outerwear'],
    paletteHex: ['#223344'],
    styleTags: ['casual'],
    formality: 1,
    rainReady: true,
    note: null,
    updatedAt: Timestamp.now(),
    revision: 0,
    schemaVersion: 1,
  };
}

async function seedBase() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'rooms', roomId), roomData());
    await setDoc(doc(db, 'rooms', otherRoomId), roomData(ownerId, [ownerId]));
    await setDoc(doc(db, 'rooms', roomId, 'members', ownerId), memberData(ownerId, 'owner'));
    await setDoc(doc(db, 'rooms', roomId, 'members', memberId), memberData(memberId));
  });
}

async function seedInvite(hash, { targetRoom = roomId, expired = false, revoked = false } = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'invites', hash), {
      roomId: targetRoom,
      createdByUid: ownerId,
      expiresAt: Timestamp.fromMillis(Date.now() + (expired ? -60_000 : 3_600_000)),
      revoked,
      createdAt: Timestamp.now(),
      revision: 0,
      schemaVersion: 1,
    });
  });
}

async function joinWithInvite(db, hash, uid, targetRoom = roomId, extraRoomField = undefined) {
  return runTransaction(db, async (transaction) => {
    const inviteRef = doc(db, 'invites', hash);
    const roomRef = doc(db, 'rooms', targetRoom);
    const invite = await transaction.get(inviteRef);
    const roomUpdate = {
      memberUids: arrayUnion(uid),
      memberCount: increment(1),
      revision: increment(1),
      updatedAt: serverTimestamp(),
    };
    if (extraRoomField) roomUpdate[extraRoomField] = true;
    transaction.update(roomRef, roomUpdate);
    transaction.set(doc(db, 'rooms', targetRoom, 'members', uid), {
      ...memberData(uid, 'member', hash),
      updatedAt: serverTimestamp(),
    });
    transaction.update(inviteRef, {
      lastJoinUid: uid,
      lastJoinAt: serverTimestamp(),
      revision: invite.data().revision + 1,
    });
  });
}

async function leaveRoom(db, uid, deleteMember = true) {
  const lookPlans = await getDocs(collection(db, 'rooms', roomId, 'lookPlans'));
  const packingItems = await getDocs(collection(db, 'rooms', roomId, 'packingItems'));
  return runTransaction(db, async (transaction) => {
    const roomRef = doc(db, 'rooms', roomId);
    const snapshot = await transaction.get(roomRef);
    const members = snapshot.data().memberUids.filter((value) => value !== uid);
    transaction.update(roomRef, {
      memberUids: members,
      memberCount: members.length,
      revision: snapshot.data().revision + 1,
      updatedAt: serverTimestamp(),
    });
    if (deleteMember) transaction.delete(doc(db, 'rooms', roomId, 'members', uid));
    transaction.delete(doc(db, 'rooms', roomId, 'availability', uid));
    lookPlans.docs
      .filter((snapshot) => snapshot.data().ownerUid === uid)
      .forEach((snapshot) => transaction.delete(snapshot.ref));
    packingItems.docs
      .filter((snapshot) => snapshot.data().assigneeUid === uid)
      .forEach((snapshot) => transaction.update(snapshot.ref, {
        assigneeUid: null,
        isPacked: false,
        revision: snapshot.data().revision + 1,
        updatedAt: serverTimestamp(),
      }));
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await seedBase();
});

after(async () => {
  await testEnv.cleanup();
});

describe('default deny and room membership', () => {
  test('1 unauthenticated room read is denied', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, 'rooms', roomId)));
  });

  test('2 unauthenticated room write is denied', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(setDoc(doc(db, 'rooms', 'anonymous-room'), roomData('anonymous', ['anonymous'])));
  });

  test('3 owner can create a valid room', async () => {
    const db = testEnv.authenticatedContext(ownerId).firestore();
    const data = roomData(ownerId, [ownerId]);
    data.updatedAt = serverTimestamp();
    await assertSucceeds(setDoc(doc(db, 'rooms', 'created-room'), data));
  });

  test('4 non-owner cannot change room metadata', async () => {
    const db = testEnv.authenticatedContext(memberId).firestore();
    await assertFails(updateDoc(doc(db, 'rooms', roomId), {
      title: 'Hijacked', revision: 1, updatedAt: serverTimestamp(),
    }));
  });

  test('5 member can read room', async () => {
    const db = testEnv.authenticatedContext(memberId).firestore();
    await assertSucceeds(getDoc(doc(db, 'rooms', roomId)));
  });

  test('6 outsider cannot read room', async () => {
    const db = testEnv.authenticatedContext(outsiderId).firestore();
    await assertFails(getDoc(doc(db, 'rooms', roomId)));
  });

  test('7 user cannot write another member availability', async () => {
    const db = testEnv.authenticatedContext(memberId).firestore();
    await assertFails(setDoc(doc(db, 'rooms', roomId, 'availability', ownerId), availabilityData(ownerId)));
  });
});

describe('invite joins', () => {
  test('8 valid invite join transaction succeeds', async () => {
    await seedInvite(validHash);
    const db = testEnv.authenticatedContext(outsiderId).firestore();
    await assertSucceeds(joinWithInvite(db, validHash, outsiderId));
  });

  test('9 expired invite join fails', async () => {
    await seedInvite(expiredHash, { expired: true });
    const db = testEnv.authenticatedContext(outsiderId).firestore();
    await assertFails(joinWithInvite(db, expiredHash, outsiderId));
  });

  test('10 revoked invite join fails', async () => {
    await seedInvite(revokedHash, { revoked: true });
    const db = testEnv.authenticatedContext(outsiderId).firestore();
    await assertFails(joinWithInvite(db, revokedHash, outsiderId));
  });

  test('11 wrong-room invite join fails', async () => {
    await seedInvite(wrongRoomHash, { targetRoom: otherRoomId });
    const db = testEnv.authenticatedContext(outsiderId).firestore();
    await assertFails(joinWithInvite(db, wrongRoomHash, outsiderId, roomId));
  });

  test('12 join cannot mutate an arbitrary room field', async () => {
    await seedInvite(validHash);
    const db = testEnv.authenticatedContext(outsiderId).firestore();
    await assertFails(joinWithInvite(db, validHash, outsiderId, roomId, 'isAdmin'));
  });

  test('13 thirteenth member cannot join', async () => {
    const members = Array.from({ length: 12 }, (_, index) => index === 0 ? ownerId : `member-${index}`);
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'rooms', roomId), roomData(ownerId, members));
    });
    await seedInvite(validHash);
    const db = testEnv.authenticatedContext(outsiderId).firestore();
    await assertFails(joinWithInvite(db, validHash, outsiderId));
  });

  test('14 invite collection list is denied', async () => {
    await seedInvite(validHash);
    const db = testEnv.authenticatedContext(memberId).firestore();
    await assertFails(getDocs(collection(db, 'invites')));
  });
});

describe('shared packing and account leave', () => {
  test('15 member can claim an unassigned packing item', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'rooms', roomId, 'packingItems', 'charger'), packingData());
    });
    const db = testEnv.authenticatedContext(memberId).firestore();
    await assertSucceeds(updateDoc(doc(db, 'rooms', roomId, 'packingItems', 'charger'), {
      assigneeUid: memberId, revision: 1, updatedAt: serverTimestamp(),
    }));
  });

  test('16 other member cannot update an assigned packing item', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'rooms', roomId, 'packingItems', 'charger'), packingData(ownerId));
    });
    const db = testEnv.authenticatedContext(memberId).firestore();
    await assertFails(updateDoc(doc(db, 'rooms', roomId, 'packingItems', 'charger'), {
      isPacked: true, revision: 1, updatedAt: serverTimestamp(),
    }));
  });

  test('17 owner can reassign a packing item', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'rooms', roomId, 'packingItems', 'charger'), packingData(ownerId));
    });
    const db = testEnv.authenticatedContext(ownerId).firestore();
    await assertSucceeds(updateDoc(doc(db, 'rooms', roomId, 'packingItems', 'charger'), {
      assigneeUid: memberId, revision: 1, updatedAt: serverTimestamp(),
    }));
  });

  test('18 member leave transaction succeeds with own document cleanup', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'rooms', roomId, 'availability', memberId), {
        ...availabilityData(memberId), updatedAt: Timestamp.now(),
      });
      await setDoc(doc(db, 'rooms', roomId, 'lookPlans', 'member_2026-09-01'), lookPlanData(memberId));
      await setDoc(doc(db, 'rooms', roomId, 'packingItems', 'charger'), packingData(memberId));
    });
    const db = testEnv.authenticatedContext(memberId).firestore();
    await assertSucceeds(leaveRoom(db, memberId, true));
  });

  test('19 member leave without member cleanup is denied', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'rooms', roomId, 'availability', memberId), {
        ...availabilityData(memberId), updatedAt: Timestamp.now(),
      });
    });
    const db = testEnv.authenticatedContext(memberId).firestore();
    await assertFails(leaveRoom(db, memberId, false));
  });
});
