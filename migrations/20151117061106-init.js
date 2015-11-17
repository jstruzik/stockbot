var dbm = global.dbm || require('db-migrate');
var type = dbm.dataType;

exports.up = function(db, callback) {
    db.createTable('stocks',
	{
	  id:
	  {
	    type: 'int',
	    unsigned: true,
	    notNull: true,
	    primaryKey: true,
	    autoIncrement: true
	  },
	  ticker:
	  {
	    type: 'string',
	    notNull: true
	  },
	  shares:
	  {
	    type: 'int',
	    unsigned: true,
	    notNull: true
	  },
	  value:
	  {
	    type: 'decimal',
	    notNull: true
	  },	
	  timestamp:
	  {
	    type: 'timestamp',
	    notNull: true,
	    defaultValue: "now()"
	  },
  	},
	callback);
};

exports.down = function(db, callback) {
  db.dropTable('stocks', callback);
};
