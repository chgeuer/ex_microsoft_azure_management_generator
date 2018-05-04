#!/bin/bash

iex -S mix \
   run -e "ExMicrosoftAzureManagementGenerator.generate_from_text_file"
