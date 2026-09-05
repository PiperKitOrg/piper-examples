// Shop collections with a users⇄teams cycle via relationship inference
// (matches piper-go testdata fixtures/mongo/shop_with_cycle.js).

db = db.getSiblingDB('shop_source');
db.dropDatabase();
db = db.getSiblingDB('shop_source');

db.teams.insertMany([
  {
    _id: ObjectId('aaaaaaaaaaaaaaaaaaaaaaaa'),
    name: 'Alpha',
    // userId (not ownerUserId) so inference matches entity "users"
    userId: ObjectId('bbbbbbbbbbbbbbbbbbbbbbbb'),
  },
]);

db.users.insertMany([
  {
    _id: ObjectId('bbbbbbbbbbbbbbbbbbbbbbbb'),
    name: 'Ada',
    email: 'ada@example.com',
    teamId: ObjectId('aaaaaaaaaaaaaaaaaaaaaaaa'),
  },
  {
    _id: ObjectId('cccccccccccccccccccccccc'),
    name: 'Grace',
    email: 'grace@example.com',
    teamId: ObjectId('aaaaaaaaaaaaaaaaaaaaaaaa'),
  },
]);

db.products.insertMany([
  {
    _id: ObjectId('dddddddddddddddddddddddd'),
    name: 'Widget',
    price: NumberDecimal('9.99'),
    active: true,
  },
  {
    _id: ObjectId('eeeeeeeeeeeeeeeeeeeeeeee'),
    name: 'Gadget',
    price: NumberDecimal('19.50'),
    active: true,
  },
]);

db.orders.insertMany([
  {
    _id: ObjectId('ffffffffffffffffffffffff'),
    userId: ObjectId('bbbbbbbbbbbbbbbbbbbbbbbb'),
    productId: ObjectId('dddddddddddddddddddddddd'),
    quantity: 2,
  },
  {
    _id: ObjectId('111111111111111111111111'),
    userId: ObjectId('cccccccccccccccccccccccc'),
    productId: ObjectId('eeeeeeeeeeeeeeeeeeeeeeee'),
    quantity: 1,
  },
]);
