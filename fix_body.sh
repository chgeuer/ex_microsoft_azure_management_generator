#!/bin/sh

echo "Fixing body handling (https://github.com/swagger-api/swagger-codegen/issues/8138)"

find clients \
   -type f \
   -name "*.ex" \
   -exec sed -i'' \
    -e 's/add_param(:body, :"parameters", parameters)/add_param(:body, :body, parameters)/g' {} +

find clients \
   -type f \
   -name "*.ex" \
   -exec sed -i'' \
    -e 's/add_param(:body, :"createUpdateParameters", create_update_parameters)/add_param(:body, :body, create_update_parameters)/g' {} +
