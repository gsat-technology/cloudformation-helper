### cloudformation-helper

This script bunches together the CLI commands and logic needed to update an AWS CloudFormation stack via command line by:
- creating a change set
- waiting for the change set to be available
- running the change set to update the stack

#### instructions

Clone this repo
```
git clone https://github.com/gsat-technology/cloudformation-helper.git
```

Add any parameter values to params.sh or empty all contents of this file if your template has no template parameters.

Run
```
./update_cf <stack_name> <path_to_template>
```

#### notes

- Tested using bash on OS X

