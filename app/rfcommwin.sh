args=("$@")
# $@ is a special array used to store bash command line arguments
# you can access these args using this format: ${arg[x]} with zero indexing
# Currently this must always run from a CLI interface with bash scripting capabilities e.g. Git, Cygwin
echo "Setting up RFCOMM bind for" ${args[0]} "on x86 host"