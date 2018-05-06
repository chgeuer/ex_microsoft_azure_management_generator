#!/bin/sh

echo "Fixing body handling (https://github.com/swagger-api/swagger-codegen/issues/8138)"

find 1 \
   -type f \
   -name "*.ex" \
   -exec sed -i'' \
    -e 's/add_param(:body, :"[^"]*", /add_param(:body, :body, /g' {} +
