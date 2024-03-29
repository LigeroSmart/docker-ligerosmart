#!/bin/bash

# elasticsearch integration
# Change WebService destination

curl -X PUT "${APP_LigeroSmart_Node}:9200/_cluster/settings?flat_settings=true&pretty" -H 'Content-Type: application/json' -d'
{
    "transient" : {
        "logger.org.elasticsearch.deprecation": "ERROR"
    }
}' > /dev/null

cat >/tmp/elasticsearch-config.yml <<EOF
---
- ${APP_LigeroSmart_Node}:9200
EOF

otrs.Console.pl Admin::Config::Update --setting-name 'LigeroSmart###Nodes' --source-path=/tmp/elasticsearch-config.yml  --no-deploy
otrs.Console.pl Admin::Config::Update --setting-name 'LigeroSmart::Index' --value "${APP_CustomerID}"  --no-deploy
otrs.Console.pl Maint::Config::Rebuild

# init elasticsearch mapping
otrs.Console.pl Admin::Ligero::Elasticsearch::MappingInstall --DefaultLanguage
