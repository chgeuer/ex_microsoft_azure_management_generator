#!/bin/bash

find clients \
   -type f \
   -name "*.ex" \
   -exec sed -i'' \
    -e 's/add_param(:body, :"parameters", parameters)/add_param(:body, :body, parameters)/g' {} +
