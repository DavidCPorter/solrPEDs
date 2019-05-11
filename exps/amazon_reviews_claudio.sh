#! /bin/bash

if [ "$#" -ne 2 ]; then
    echo 'Usage: amazon_review.sh <username> <solr_path>'
    exit
fi

SCHEMA='reviews'
DATASET_PATH='../reviews_Electronics_5.json'
SCHEMA_PATH='../amazon_review_schema.json'

USER=$1
SOLR_PATH=$2

if ssh $USER@node0 "cd $SOLR_PATH/bin/"
    then 
        echo 'Solr code found'
    else 
        echo "Solr code not found at: $SOLR_PATH"
        exit
fi

#if ssh $USER@node0 stat $SOLR_PATH/bin/solr \> /dev/null 2\>\&1    
#    then 
#        echo "Path to Solr not valid: $SOLR_PATH"
#        exit
#fi

echo 'Downloading the amazon dataset'
ssh $USER@node0 "wget http://snap.stanford.edu/data/amazon/productGraph/categoryFiles/reviews_Electronics_5.json.gz" > ./node0.out

echo 'Uncompressing the amazon dataset'
ssh $USER@node0 "gunzip reviews_Electronics_5.json.gz" >> ./node0.out

echo 'Stopping and restarting the solrCloud instance'
ssh $USER@node0 "cd $SOLR_PATH; ./bin/solr stop -all" >> node0.out
ssh $USER@node0 "cd $SOLR_PATH; ./bin/solr start -c -p 8983 -z 10.10.1.1:2181,10.10.1.2:2181,10.10.1.3:2181 -force" >> node0.out

echo 'Creating a new collection for reviews: replication factor = 3, sharding = 3'
ssh $USER@node0 "cd $SOLR_PATH; ./bin/solr create_collection -c $SCHEMA -s 3 -rf 3 -force" >> node0.out

IP=$(ssh $USER@node0 "ifconfig | awk '/inet/ {print \$2}' | head -n 1")

echo 'Posting the new collection on the solrCloud instance'
curl http://$IP:8983/solr/$SCHEMA/schema -X POST -H 'Content-type:application/json' --data-binary '{
    "add-field" : {
        "name":"reviewerID",
        "type":"text_general",
        "multiValued":false,
        "stored":true
    },
    "add-field" : {
        "name":"asin",
        "type":"string",
        "multiValued":true,
        "stored":true
    },
    "add-field" : {
        "name":"reviewerName",
        "type":"string",
        "multiValued":true,
        "stored":true
    },
    "add-field" : {
        "name":"reviewText",
        "type":"text_general",
        "stored":true
    },
    "add-field" : {
        "name":"overall",
        "type":"string",
        "multiValued":true,
        "stored":true
    },
    "add-field" : {
        "name":"summary",
        "type":"text_general",
        "multiValued":true,
        "stored":true
    } 
}' >> node0.out

ssh $USER@node0 "cd $SOLR_PATH; ./bin/post -c $SCHEMA $DATASET_PATH" >> node0.out

curl http://$IP:8983/solr/$SCHEMA/config/params -H 'Content-type:application/json'  -d '{
"update" : {
  "facets": {
    "facet.field":"asin"
    }
  }
}' >> node0.out
