# About

I need to establish two nodes: 

## Node 1

- A vault client

- Noman server

- Go CI

## Node 2

- Nomad agent

- The actual autograder CI

- any of the running jobs

# TODO

- [ ] Use a configuration file for consul instead of passing flags

- [ ] Adjust the count of the minions so to have a quorum.

- [ ] Change the ownership of the consul data directory (make it a consul user)

- [x] Teardown the "template output directory" on TF destroy

- [x] Template the provisioning script so it embeds the IP addresses and versions

- [x] Fix the provisioning script to work

- [x] Parameterize the version of consul in the bash scripts with a readonly constant

- [x] Set -x and -u -e
