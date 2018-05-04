#!/bin/bash

find . \
   -type f \
   -name "*.ex" \
   -exec sed -i'' \
    -e 's/add_param(:body, :"parameters", parameters)/add_param(:body, :body, parameters)/g' {} +
