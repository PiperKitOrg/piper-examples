// Shop collections for Mongo → relational migration testing.
//
// Exercises:
// - Mongo ObjectId → relational primary/foreign keys
// - inferred relationships
// - users ⇄ teams circular dependency
// - 1:N and N:1 relationships
// - nullable relationships
// - orphan/empty parent records
// - Decimal128 → relational NUMERIC/DECIMAL
// - boolean true/false
// - integer quantities
// - timestamps
// - repeated references
// - sparse/missing fields
//
// Relationship inference:
//   teams.userId      → users._id
//   users.teamId      → teams._id
//   orders.userId     → users._id
//   orders.productId  → products._id

db = db.getSiblingDB('shop_source');
db.dropDatabase();
db = db.getSiblingDB('shop_source');


// ------------------------------------------------------------
// Teams
// ------------------------------------------------------------

db.teams.insertMany([
  {
    _id: ObjectId('aaaaaaaaaaaaaaaaaaaaaaaa'),
    name: 'Alpha',

    // Circular relationship:
    // teams.userId → users._id
    userId: ObjectId('bbbbbbbbbbbbbbbbbbbbbbbb'),
  },
  {
    _id: ObjectId('abababababababababababab'),
    name: 'Beta',

    // No owner/user.
    // Tests nullable FK preservation.
    userId: null,
  },
  {
    _id: ObjectId('acacacacacacacacacacacac'),
    name: 'Gamma',

    // No users reference this team.
    // Tests an empty parent.
    userId: null,
  },
]);


// ------------------------------------------------------------
// Users
// ------------------------------------------------------------

db.users.insertMany([
  {
    _id: ObjectId('bbbbbbbbbbbbbbbbbbbbbbbb'),
    name: 'Ada',
    email: 'ada@example.com',

    // Circular relationship:
    // users.teamId → teams._id
    teamId: ObjectId('aaaaaaaaaaaaaaaaaaaaaaaa'),
  },
  {
    _id: ObjectId('cccccccccccccccccccccccc'),
    name: 'Grace',
    email: 'grace@example.com',
    teamId: ObjectId('aaaaaaaaaaaaaaaaaaaaaaaa'),
  },
  {
    _id: ObjectId('cdcdcdcdcdcdcdcdcdcdcdcd'),
    name: 'Linus',
    email: 'linus@example.com',

    // User without a team.
    teamId: null,
  },
]);


// ------------------------------------------------------------
// Products
// ------------------------------------------------------------

db.products.insertMany([
  {
    _id: ObjectId('dddddddddddddddddddddddd'),
    name: 'Widget',

    // Exact decimal value.
    price: NumberDecimal('9.99'),

    active: true,
  },
  {
    _id: ObjectId('eeeeeeeeeeeeeeeeeeeeeeee'),
    name: 'Gadget',

    // Different scale.
    price: NumberDecimal('19.5000'),

    active: true,
  },
  {
    _id: ObjectId('dededededededededededede'),
    name: 'Premium Box',

    // Larger exact decimal.
    price: NumberDecimal('123456789.1234'),

    active: true,
  },
  {
    _id: ObjectId('dfdfdfdfdfdfdfdfdfdfdfdf'),
    name: 'Legacy Cable',

    // Zero + false exercises edge-ish scalar values.
    price: NumberDecimal('0.00'),

    active: false,
  },
]);


// ------------------------------------------------------------
// Orders
// ------------------------------------------------------------

db.orders.insertMany([
  {
    _id: ObjectId('ffffffffffffffffffffffff'),

    userId: ObjectId('bbbbbbbbbbbbbbbbbbbbbbbb'),
    productId: ObjectId('dddddddddddddddddddddddd'),

    quantity: 2,

    createdAt: ISODate('2026-01-10T10:00:00Z'),
  },
  {
    _id: ObjectId('111111111111111111111111'),

    userId: ObjectId('bbbbbbbbbbbbbbbbbbbbbbbb'),
    productId: ObjectId('eeeeeeeeeeeeeeeeeeeeeeee'),

    quantity: 1,

    createdAt: ISODate('2026-01-11T11:30:00Z'),
  },
  {
    _id: ObjectId('121212121212121212121212'),

    userId: ObjectId('bbbbbbbbbbbbbbbbbbbbbbbb'),
    productId: ObjectId('dddddddddddddddddddddddd'),

    // Repeated product reference.
    quantity: 5,

    createdAt: ISODate('2026-01-15T09:15:00Z'),
  },
  {
    _id: ObjectId('131313131313131313131313'),

    userId: ObjectId('cccccccccccccccccccccccc'),
    productId: ObjectId('dededededededededededede'),

    quantity: 100,

    createdAt: ISODate('2026-02-01T14:00:00Z'),
  },
  {
    _id: ObjectId('141414141414141414141414'),

    userId: ObjectId('cccccccccccccccccccccccc'),
    productId: ObjectId('dfdfdfdfdfdfdfdfdfdfdfdf'),

    // Explicitly references an inactive product.
    quantity: 1,

    createdAt: ISODate('2026-02-03T16:45:00Z'),
  },
]);