$ rake db:create # create the db
$ rake db:migrate # run migrations
$ rake db:drop # delete the db
$ rake db:reset # combination of the upper three
$ rake db:schema # creates a schema file of the current database
$ rake g:migration your_migration # generates a new migration file

rake dependencies
active 'products' > variants > options [linked via foreign key]
  -product indexes should be in sequence 1...n w/o duplicates
  no dependencies

active 'custom_collection'
  -indexes should be in correct sequence
  no dependencies

active 'collects'
  no dependencies

staging 'collects'
  +staging_custom_collections
  +staging_products
  +products
  +custom_collections

active 'pages'
  no dependencies

'staging_custom_collections'
  no dependencies

'staging_products'
  no dependencies

active 'product_metafields'
  +products

staging 'product_metafields'
  +products
  +staging_products
  +active product_metafields
