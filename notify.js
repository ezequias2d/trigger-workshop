const { db } = require('./database');
const createSubscriber = require("pg-listen");

(async function () {
  const DATABASE_HOST = db.host;
  const DATABASE_USER = db.user;
  const DATABASE_PASSWORD = db.password;
  const DATABASE_PORT = db.port;
  const DATABASE = db.database;

  const eventName = "db_event";

  //  Create listener for db
  const subscriber = createSubscriber({
    connectionString: `postgres://${DATABASE_USER}:${DATABASE_PASSWORD}@${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE}?sslmode=require`,
  });
  await subscriber.connect();
  await subscriber.listenTo(eventName);

  subscriber.notifications.on(eventName, async (data) => {
    console.log(data);
  });
})();
