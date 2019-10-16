# Copyright (c) 2019 Miguel Angel Rivera Notararigo
# Released under the MIT License

#########
# RULES #
#########
# SUPER_USER=true
# ENV=
# EXEC_MODE=system
# BIN_DEPS=
#########

main() {
  run_su apt-get autoremove -y

  run_su rm -rf /var/cache/apt
  run_su mkdir /var/cache/apt

  run_su rm -rf /var/lib/apt/lists
  run_su mkdir /var/lib/apt/lists

  run_su rm -rf /var/log
  run_su mkdir /var/log
}
