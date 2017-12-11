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

Create a configuration file as per `example_config.yml`

- `name`: the name of the stack you are updating
- `template`: path (relative to cfh_update.yml) to your cloudformation template file
- `parameters`: key/values for cloudformation template parameters (if any)

Run
```
./cfh_helper <path_to_example_config.yml>
```

#### notes

- when using this, it might be useful just to keep the config file in the same directory as the cloudformation template and tracked in git (or perhaps not, if it contains secrets)
- tested using bash on OS X
- prob will fail on linux but I will fix at some point
