// Emulator tests for firestore.rules (PRD section 9).
//
// Every `match` block in the rules gets a `describe` here, and every allow and
// deny branch gets at least one case.
//
// Run with:  npm test   (starts the emulator, runs these, shuts it down)

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const PROJECT_ID = 'nh-fitness-8a972';

/** Admin uid; `admins/OWNER` is seeded, the way the Console creates it. */
const OWNER = 'owner-uid';

/** The gym's proprietor: `owners/PROPRIETOR`, with no `admins` entry. */
const PROPRIETOR = 'proprietor-uid';

/** A member who has joined before (`hasJoined: true`). */
const RENEWER = 'renewer-uid';

/** A brand-new member who has never joined (`hasJoined: false`). */
const NEWBIE = 'newbie-uid';

/** A member whose membership has ended. */
const LAPSED = 'lapsed-uid';

const DAY = 24 * 60 * 60 * 1000;
const future = () => new Date(Date.now() + 30 * DAY);
const past = () => new Date(Date.now() - 30 * DAY);

let testEnv;

/** Seed values matching PRD section 8.2. */
const SETTINGS = {
  registrationFee: 500,
  ptFee: 5000,
  ptFreeDays: 7,
  upiId: 'gym@upi',
  upiName: 'NH Fitness',
  approvalTimeText: 'within a few hours during gym timings',
  address: 'Somewhere',
  timings: '6am - 10pm',
  phone: '9999999999',
  email: 'gym@example.com',
  instagramUrl: 'https://example.com',
  supplementsEnabled: false,
  clothesEnabled: false,
};

/** A valid pending UPI request from NEWBIE for the yearly plan with PT. */
function validRequest(overrides = {}) {
  return {
    uid: NEWBIE,
    userName: 'Newbie',
    userPhone: '9000000000',
    planId: 'yearly',
    planName: 'Yearly',
    months: 12,
    planPrice: 15000,
    registrationFee: 500,
    ptFee: 5000,
    withPT: true,
    total: 20500,
    method: 'upi',
    upiRef: '123456789012',
    status: 'pending',
    createdBy: NEWBIE,
    ...overrides,
  };
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();

    // The gym's proprietor: an `owners` entry and no `admins` entry, proving
    // an owner keeps full access without one.
    await setDoc(doc(db, 'owners', PROPRIETOR), {
      name: 'Proprietor',
      addedAt: new Date(),
    });

    await setDoc(doc(db, 'admins', OWNER), {
      name: 'Owner',
      addedAt: new Date(),
    });
    await setDoc(doc(db, 'settings', 'app'), SETTINGS);

    await setDoc(doc(db, 'plans', 'yearly'), {
      name: 'Yearly',
      months: 12,
      price: 15000,
      sortOrder: 4,
      isBestValue: true,
      active: true,
    });
    await setDoc(doc(db, 'plans', 'retired'), {
      name: 'Retired plan',
      months: 1,
      price: 1000,
      sortOrder: 9,
      isBestValue: false,
      active: false,
    });

    await setDoc(doc(db, 'users', NEWBIE), {
      name: 'Newbie',
      email: 'newbie@example.com',
      phone: '9000000000',
      hasJoined: false,
      ptFreeDaysUsed: 0,
    });
    await setDoc(doc(db, 'users', RENEWER), {
      name: 'Renewer',
      email: 'renewer@example.com',
      phone: '9000000001',
      hasJoined: true,
      ptFreeDaysUsed: 2,
      activeUntil: future(),
      currentMembershipId: 'm-renewer',
    });
    await setDoc(doc(db, 'users', LAPSED), {
      name: 'Lapsed',
      email: 'lapsed@example.com',
      hasJoined: true,
      ptFreeDaysUsed: 7,
      activeUntil: past(),
      currentMembershipId: 'm-lapsed',
    });

    await setDoc(doc(db, 'memberships', 'm-renewer'), {
      uid: RENEWER,
      planId: 'yearly',
      planName: 'Yearly',
      months: 12,
      withPT: false,
      startDate: past(),
      endDate: future(),
      paymentRequestId: 'r-renewer',
    });

    await setDoc(doc(db, 'paymentRequests', 'r-renewer'), {
      ...validRequest({ uid: RENEWER, createdBy: RENEWER, registrationFee: 0, total: 20000 }),
      status: 'approved',
    });
    await setDoc(doc(db, 'paymentRequests', 'r-pending'), validRequest());

    await setDoc(doc(db, 'classes', 'published-class'), {
      title: 'Full body',
      description: '',
      category: 'Strength',
      durationMin: 30,
      youtubeUrl: 'https://youtu.be/aaaaaaaaaaa',
      thumbnailUrl: '',
      published: true,
      sortOrder: 1,
    });
    await setDoc(doc(db, 'classes', 'draft-class'), {
      title: 'Not ready',
      description: '',
      category: 'Strength',
      durationMin: 20,
      youtubeUrl: 'https://youtu.be/bbbbbbbbbbb',
      thumbnailUrl: '',
      published: false,
      sortOrder: 2,
    });

    await setDoc(doc(db, 'announcements', 'a1'), {
      title: 'Holi closed',
      message: 'The gym is closed on Holi.',
      active: true,
    });
  });
});

const asOwner = () => testEnv.authenticatedContext(OWNER).firestore();
const asNewbie = () => testEnv.authenticatedContext(NEWBIE).firestore();
const asRenewer = () => testEnv.authenticatedContext(RENEWER).firestore();
const asLapsed = () => testEnv.authenticatedContext(LAPSED).firestore();
const asVisitor = () => testEnv.unauthenticatedContext().firestore();
const asProprietor = () =>
  testEnv.authenticatedContext(PROPRIETOR).firestore();

// ── admins ───────────────────────────────────────────────────────────────────

describe('owners/{uid}', () => {
  it('lets an owner read their own entry', async () => {
    await assertSucceeds(getDoc(doc(asProprietor(), 'owners', PROPRIETOR)));
  });

  it('lets an admin see who the owners are', async () => {
    await assertSucceeds(getDoc(doc(asOwner(), 'owners', PROPRIETOR)));
  });

  it('denies a member reading the owner list', async () => {
    await assertFails(getDoc(doc(asNewbie(), 'owners', PROPRIETOR)));
  });

  it('denies writing the owner list — even to an owner', async () => {
    // The root of trust: owners exist only in the Console, so no app bug and
    // no stolen session can mint one.
    await assertFails(
      setDoc(doc(asProprietor(), 'owners', NEWBIE), { name: 'x' }),
    );
    await assertFails(
      setDoc(doc(asOwner(), 'owners', OWNER), { name: 'x' }),
    );
    await assertFails(deleteDoc(doc(asProprietor(), 'owners', PROPRIETOR)));
  });

  it('treats an owner as an admin without an admins entry', async () => {
    // PROPRIETOR is in `owners` only, yet gets everything an admin can do.
    await assertSucceeds(getDoc(doc(asProprietor(), 'users', NEWBIE)));
    await assertSucceeds(
      updateDoc(doc(asProprietor(), 'plans', 'yearly'), { price: 16000 }),
    );
    await assertSucceeds(
      getDoc(doc(asProprietor(), 'classes', 'draft-class')),
    );
  });
});

describe('admins/{uid} — staff management', () => {
  const staffEntry = () => ({
    name: 'New Staff',
    addedAt: new Date(),
    addedBy: PROPRIETOR,
  });

  it('lets an owner grant admin access', async () => {
    await assertSucceeds(
      setDoc(doc(asProprietor(), 'admins', NEWBIE), staffEntry()),
    );
  });

  it('lets an owner revoke admin access', async () => {
    await assertSucceeds(deleteDoc(doc(asProprietor(), 'admins', OWNER)));
  });

  it('denies an ordinary admin adding another admin', async () => {
    // The whole point of two tiers: staff cannot recruit staff.
    await assertFails(
      setDoc(doc(asOwner(), 'admins', NEWBIE), {
        name: 'New Staff',
        addedAt: new Date(),
        addedBy: OWNER,
      }),
    );
  });

  it('denies an ordinary admin removing another admin', async () => {
    // So one compromised staff login cannot lock the owner out.
    await assertFails(deleteDoc(doc(asOwner(), 'admins', OWNER)));
  });

  it('denies a member promoting themselves', async () => {
    await assertFails(
      setDoc(doc(asNewbie(), 'admins', NEWBIE), {
        name: 'Sneaky',
        addedAt: new Date(),
        addedBy: NEWBIE,
      }),
    );
  });

  it('denies an entry that lies about who granted it', async () => {
    await assertFails(
      setDoc(doc(asProprietor(), 'admins', NEWBIE), {
        ...staffEntry(),
        addedBy: OWNER,
      }),
    );
  });

  it('denies an entry carrying unexpected fields', async () => {
    await assertFails(
      setDoc(doc(asProprietor(), 'admins', NEWBIE), {
        ...staffEntry(),
        superUser: true,
      }),
    );
  });

  it('denies an entry with no real addedAt timestamp', async () => {
    await assertFails(
      setDoc(doc(asProprietor(), 'admins', NEWBIE), {
        name: 'New Staff',
        addedAt: 'yesterday',
        addedBy: PROPRIETOR,
      }),
    );
  });
});

describe('admins/{uid}', () => {
  it('lets a user read their own admin document', async () => {
    await assertSucceeds(getDoc(doc(asOwner(), 'admins', OWNER)));
  });

  it('lets a member check their own (absent) admin document', async () => {
    // The app does exactly this to decide whether to show the Admin link.
    await assertSucceeds(getDoc(doc(asNewbie(), 'admins', NEWBIE)));
  });

  it('denies reading someone else\'s admin document', async () => {
    await assertFails(getDoc(doc(asNewbie(), 'admins', OWNER)));
  });

  it('denies writing the admin list, even to an admin', async () => {
    // PRD section 2: there is no sign-up path to become admin.
    await assertFails(setDoc(doc(asOwner(), 'admins', NEWBIE), { name: 'x' }));
    await assertFails(setDoc(doc(asNewbie(), 'admins', NEWBIE), { name: 'x' }));
  });

  it('denies an unauthenticated read', async () => {
    await assertFails(getDoc(doc(asVisitor(), 'admins', OWNER)));
  });
});

// ── users ────────────────────────────────────────────────────────────────────

describe('users/{uid}', () => {
  it('lets a member read their own profile', async () => {
    await assertSucceeds(getDoc(doc(asNewbie(), 'users', NEWBIE)));
  });

  it('denies reading another member\'s profile', async () => {
    await assertFails(getDoc(doc(asNewbie(), 'users', RENEWER)));
  });

  it('lets an admin read any profile', async () => {
    await assertSucceeds(getDoc(doc(asOwner(), 'users', NEWBIE)));
  });

  it('accepts the exact create shape the app writes', async () => {
    const db = testEnv.authenticatedContext('fresh-uid').firestore();
    await assertSucceeds(
      setDoc(doc(db, 'users', 'fresh-uid'), {
        name: 'Fresh',
        email: 'fresh@example.com',
        phone: '',
        createdAt: new Date(),
        hasJoined: false,
        ptFreeDaysUsed: 0,
        updatedAt: new Date(),
      }),
    );
  });

  it('denies a create carrying an unexpected field', async () => {
    const db = testEnv.authenticatedContext('fresh-uid').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'fresh-uid'), {
        name: 'Fresh',
        email: 'fresh@example.com',
        hasJoined: false,
        ptFreeDaysUsed: 0,
        activeUntil: future(),
      }),
    );
  });

  it('denies a create that grants itself a membership', async () => {
    const db = testEnv.authenticatedContext('fresh-uid').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'fresh-uid'), {
        name: 'Fresh',
        email: 'fresh@example.com',
        hasJoined: true,
        ptFreeDaysUsed: 0,
      }),
    );
  });

  it('denies a create that starts ptFreeDaysUsed above zero', async () => {
    const db = testEnv.authenticatedContext('fresh-uid').firestore();
    await assertFails(
      setDoc(doc(db, 'users', 'fresh-uid'), {
        name: 'Fresh',
        email: 'fresh@example.com',
        hasJoined: false,
        ptFreeDaysUsed: 3,
      }),
    );
  });

  it('denies creating a profile for somebody else', async () => {
    await assertFails(
      setDoc(doc(asNewbie(), 'users', 'someone-else'), {
        name: 'Nope',
        email: 'nope@example.com',
        hasJoined: false,
        ptFreeDaysUsed: 0,
      }),
    );
  });

  it('lets a member change name, phone and updatedAt', async () => {
    await assertSucceeds(
      updateDoc(doc(asNewbie(), 'users', NEWBIE), {
        name: 'Newbie Kumar',
        phone: '9000000009',
        updatedAt: new Date(),
      }),
    );
  });

  it('denies a member extending their own membership', async () => {
    await assertFails(
      updateDoc(doc(asNewbie(), 'users', NEWBIE), { activeUntil: future() }),
    );
  });

  it('denies a member flipping hasJoined', async () => {
    await assertFails(
      updateDoc(doc(asNewbie(), 'users', NEWBIE), { hasJoined: true }),
    );
  });

  it('denies a member moving their own free PT counter', async () => {
    await assertFails(
      updateDoc(doc(asNewbie(), 'users', NEWBIE), { ptFreeDaysUsed: 0 }),
    );
  });

  it('lets an admin change the admin-only fields', async () => {
    await assertSucceeds(
      updateDoc(doc(asOwner(), 'users', NEWBIE), {
        hasJoined: true,
        activeUntil: future(),
        currentMembershipId: 'm-new',
        ptFreeDaysUsed: 1,
      }),
    );
  });

  it('denies deleting a profile, member or admin', async () => {
    await assertFails(deleteDoc(doc(asNewbie(), 'users', NEWBIE)));
    await assertFails(deleteDoc(doc(asOwner(), 'users', NEWBIE)));
  });
});

// ── plans ────────────────────────────────────────────────────────────────────

describe('plans/{planId}', () => {
  it('is readable by a visitor who is not logged in', async () => {
    // PRD HOME-1: prices come from Firestore on the public home page.
    await assertSucceeds(getDoc(doc(asVisitor(), 'plans', 'yearly')));
  });

  it('denies a member changing a price', async () => {
    await assertFails(
      updateDoc(doc(asNewbie(), 'plans', 'yearly'), { price: 1 }),
    );
  });

  it('lets an admin change a price', async () => {
    await assertSucceeds(
      updateDoc(doc(asOwner(), 'plans', 'yearly'), { price: 16000 }),
    );
  });

  it('lets an admin create a plan', async () => {
    await assertSucceeds(
      setDoc(doc(asOwner(), 'plans', 'weekly'), {
        name: 'Weekly',
        months: 1,
        price: 600,
        sortOrder: 0,
        isBestValue: false,
        active: true,
      }),
    );
  });
});

// ── settings ─────────────────────────────────────────────────────────────────

describe('settings/{docId}', () => {
  it('is readable by a visitor', async () => {
    await assertSucceeds(getDoc(doc(asVisitor(), 'settings', 'app')));
  });

  it('denies a member editing the gym settings', async () => {
    await assertFails(
      updateDoc(doc(asNewbie(), 'settings', 'app'), { registrationFee: 0 }),
    );
  });

  it('lets an admin edit the gym settings', async () => {
    await assertSucceeds(
      updateDoc(doc(asOwner(), 'settings', 'app'), { registrationFee: 600 }),
    );
  });
});

// ── paymentRequests ──────────────────────────────────────────────────────────

describe('paymentRequests/{id}', () => {
  it('lets a member read their own request', async () => {
    await assertSucceeds(getDoc(doc(asNewbie(), 'paymentRequests', 'r-pending')));
  });

  it('denies reading another member\'s request', async () => {
    await assertFails(getDoc(doc(asRenewer(), 'paymentRequests', 'r-pending')));
  });

  it('lets an admin read any request', async () => {
    await assertSucceeds(getDoc(doc(asOwner(), 'paymentRequests', 'r-pending')));
  });

  it('denies an unauthenticated read', async () => {
    await assertFails(getDoc(doc(asVisitor(), 'paymentRequests', 'r-pending')));
  });

  it('accepts a valid pending UPI request', async () => {
    await assertSucceeds(
      setDoc(doc(asNewbie(), 'paymentRequests', 'new-1'), validRequest()),
    );
  });

  it('accepts a cash request with no UTR', async () => {
    await assertSucceeds(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'new-cash'),
        validRequest({ method: 'cash', upiRef: null }),
      ),
    );
  });

  it('denies a tampered plan price', async () => {
    // PRD PAY-2: the rules reject a request whose prices do not match.
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'bad-price'),
        validRequest({ planPrice: 1, total: 5501 }),
      ),
    );
  });

  it('denies a total that does not add up', async () => {
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'bad-total'),
        validRequest({ total: 1 }),
      ),
    );
  });

  it('denies a request for a switched-off plan', async () => {
    // PRD PLAN-2: inactive plans are hidden, and cannot be bought.
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'bad-plan'),
        validRequest({
          planId: 'retired',
          planName: 'Retired plan',
          months: 1,
          planPrice: 1000,
          total: 6500,
        }),
      ),
    );
  });

  it('denies a UTR that is not 12 digits', async () => {
    // PRD PAY-3.
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'bad-utr-short'),
        validRequest({ upiRef: '12345678901' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'bad-utr-letters'),
        validRequest({ upiRef: '12345678901a' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'bad-utr-null'),
        validRequest({ upiRef: null }),
      ),
    );
  });

  it('denies a payment method that is not UPI or cash', async () => {
    // Card and net banking are Phase 2 (PRD section 7.4).
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'bad-method'),
        validRequest({ method: 'card' }),
      ),
    );
  });

  it('denies a member creating an already-approved request', async () => {
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'self-approved'),
        validRequest({ status: 'approved' }),
      ),
    );
  });

  it('denies a request filed under somebody else\'s uid', async () => {
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'wrong-uid'),
        validRequest({ uid: RENEWER }),
      ),
    );
  });

  it('denies a mismatched createdBy', async () => {
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'wrong-creator'),
        validRequest({ createdBy: OWNER }),
      ),
    );
  });

  it('denies a request that carries a membershipId or reviewedBy', async () => {
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'with-membership'),
        validRequest({ membershipId: 'm-fake' }),
      ),
    );
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'with-reviewer'),
        validRequest({ reviewedBy: OWNER }),
      ),
    );
  });

  it('denies a PT fee that does not match the add-on choice', async () => {
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'bad-pt'),
        validRequest({ withPT: true, ptFee: 0, total: 15500 }),
      ),
    );
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'bad-pt-2'),
        validRequest({ withPT: false, ptFee: 5000, total: 20500 }),
      ),
    );
  });

  it('denies a registration fee that is not 0 or the configured amount', async () => {
    await assertFails(
      setDoc(
        doc(asNewbie(), 'paymentRequests', 'bad-reg'),
        validRequest({ registrationFee: 250, total: 20250 }),
      ),
    );
  });

  it('denies a returning member being charged the registration fee', async () => {
    // PRD PLAN-3: charged on a member's first membership only.
    await assertFails(
      setDoc(
        doc(asRenewer(), 'paymentRequests', 'renew-with-reg'),
        validRequest({ uid: RENEWER, createdBy: RENEWER }),
      ),
    );
  });

  it('accepts a returning member paying no registration fee', async () => {
    await assertSucceeds(
      setDoc(
        doc(asRenewer(), 'paymentRequests', 'renew-no-reg'),
        validRequest({
          uid: RENEWER,
          createdBy: RENEWER,
          registrationFee: 0,
          total: 20000,
        }),
      ),
    );
  });

  it('denies a member reviewing their own request', async () => {
    // PRD ADM-1: only an admin may approve.
    await assertFails(
      updateDoc(doc(asNewbie(), 'paymentRequests', 'r-pending'), {
        status: 'approved',
      }),
    );
  });

  it('lets an admin approve and reject', async () => {
    await assertSucceeds(
      updateDoc(doc(asOwner(), 'paymentRequests', 'r-pending'), {
        status: 'approved',
        reviewedBy: OWNER,
        membershipId: 'm-new',
      }),
    );
  });

  it('lets an admin record a desk cash payment as approved', async () => {
    // PRD section 7.10: "Record cash payment" writes an approved request.
    await assertSucceeds(
      setDoc(
        doc(asOwner(), 'paymentRequests', 'desk-cash'),
        validRequest({
          method: 'cash',
          upiRef: null,
          status: 'approved',
          createdBy: OWNER,
          reviewedBy: OWNER,
          membershipId: 'm-desk',
        }),
      ),
    );
  });

  it('denies a member deleting a request, and allows an admin', async () => {
    await assertFails(deleteDoc(doc(asNewbie(), 'paymentRequests', 'r-pending')));
    await assertSucceeds(deleteDoc(doc(asOwner(), 'paymentRequests', 'r-pending')));
  });
});

// ── memberships ──────────────────────────────────────────────────────────────

describe('memberships/{id}', () => {
  it('lets a member read their own membership', async () => {
    await assertSucceeds(getDoc(doc(asRenewer(), 'memberships', 'm-renewer')));
  });

  it('denies reading another member\'s membership', async () => {
    await assertFails(getDoc(doc(asNewbie(), 'memberships', 'm-renewer')));
  });

  it('lets an admin read and write memberships', async () => {
    await assertSucceeds(getDoc(doc(asOwner(), 'memberships', 'm-renewer')));
    await assertSucceeds(
      updateDoc(doc(asOwner(), 'memberships', 'm-renewer'), {
        endDate: future(),
      }),
    );
  });

  it('denies a member creating or extending a membership', async () => {
    await assertFails(
      setDoc(doc(asNewbie(), 'memberships', 'm-self'), {
        uid: NEWBIE,
        planId: 'yearly',
        planName: 'Yearly',
        months: 12,
        withPT: false,
        startDate: new Date(),
        endDate: future(),
        paymentRequestId: 'r-pending',
      }),
    );
    await assertFails(
      updateDoc(doc(asRenewer(), 'memberships', 'm-renewer'), {
        endDate: future(),
      }),
    );
  });
});

// ── classes ──────────────────────────────────────────────────────────────────

describe('classes/{id}', () => {
  it('lets an active member read a published class', async () => {
    await assertSucceeds(getDoc(doc(asRenewer(), 'classes', 'published-class')));
  });

  it('lets an active member run the published query the app uses', async () => {
    // PRD section 9: member queries must include where('published','==',true).
    await assertSucceeds(
      getDocs(
        query(
          collection(asRenewer(), 'classes'),
          where('published', '==', true),
        ),
      ),
    );
  });

  it('denies an active member reading an unpublished class', async () => {
    await assertFails(getDoc(doc(asRenewer(), 'classes', 'draft-class')));
  });

  it('denies a member whose membership has ended', async () => {
    // PRD CLS-1.
    await assertFails(getDoc(doc(asLapsed(), 'classes', 'published-class')));
  });

  it('denies a member who never joined', async () => {
    await assertFails(getDoc(doc(asNewbie(), 'classes', 'published-class')));
  });

  it('denies a visitor who is not logged in', async () => {
    await assertFails(getDoc(doc(asVisitor(), 'classes', 'published-class')));
  });

  it('lets an admin read drafts and write classes', async () => {
    await assertSucceeds(getDoc(doc(asOwner(), 'classes', 'draft-class')));
    await assertSucceeds(
      updateDoc(doc(asOwner(), 'classes', 'draft-class'), { published: true }),
    );
  });

  it('denies a member writing a class', async () => {
    await assertFails(
      updateDoc(doc(asRenewer(), 'classes', 'published-class'), {
        title: 'Hacked',
      }),
    );
  });
});

// ── announcements ────────────────────────────────────────────────────────────

describe('announcements/{id}', () => {
  it('is readable by a visitor', async () => {
    // PRD section 7.9: the strip shows on the public home page too.
    await assertSucceeds(getDoc(doc(asVisitor(), 'announcements', 'a1')));
  });

  it('denies a member writing an announcement', async () => {
    await assertFails(
      updateDoc(doc(asNewbie(), 'announcements', 'a1'), { message: 'Hacked' }),
    );
  });

  it('lets an admin create and edit announcements', async () => {
    await assertSucceeds(
      setDoc(doc(asOwner(), 'announcements', 'a2'), {
        title: 'New trainer',
        message: 'Say hello to our new trainer.',
        active: true,
      }),
    );
    await assertSucceeds(
      updateDoc(doc(asOwner(), 'announcements', 'a1'), { active: false }),
    );
  });
});
