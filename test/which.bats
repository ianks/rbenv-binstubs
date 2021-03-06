#!/usr/bin/env bats

load test_helper

create_executable() {
  local bin
  if [[ $1 == */* ]]; then bin="$1"
  else bin="${RBENV_ROOT}/versions/${1}/bin"
  fi
  mkdir -p "$bin"
  touch "${bin}/$2"
  chmod +x "${bin}/$2"
}

#------------------------------------------------------------------------
# Standard unquoted config


@test "outputs path to gem executable when not under rails app directory" {
  create_executable "1.8" "rake"
  create_Gemfile
  create_bundle_config ''
  create_binstub "rake"

  RBENV_VERSION=1.8 run rbenv-which rake
  assert_success "${RBENV_ROOT}/versions/1.8/bin/rake"
}


@test "outputs path to binstub executable when under railsapp directory with local config" {
  create_executable "1.8" "rake"
  create_Gemfile
  create_bundle_config ''
  create_binstub "rake"

  (
    cd $RAILS_ROOT
    RBENV_VERSION=1.8 run rbenv-which rake
    assert_success "${RAILS_ROOT}/$TEST_BUNDLE_BIN/rake"

    mkdir tmp
    cd tmp

    RBENV_VERSION=1.8 run rbenv-which rake
    assert_success "${RAILS_ROOT}/$TEST_BUNDLE_BIN/rake"
  )
}

@test "outputs path to binstub executable when under railsapp directory with global config" {
  create_executable "1.8" "rake"
  create_Gemfile
  create_global_bundle_config
  create_binstub "rake"

  (
    cd $RAILS_ROOT
    RBENV_VERSION=1.8 run rbenv-which rake
    assert_success "${RAILS_ROOT}/$TEST_BUNDLE_BIN/rake"

    mkdir tmp
    cd tmp

    RBENV_VERSION=1.8 run rbenv-which rake
    assert_success "${RAILS_ROOT}/$TEST_BUNDLE_BIN/rake"
  )
}

@test "requires Gemfile to find binstub executable" {
  create_executable "1.8" "rake"
  create_bundle_config ''
  create_binstub "rake"

  (
    cd $RAILS_ROOT
    RBENV_VERSION=1.8 run rbenv-which rake
    assert_success "${RBENV_ROOT}/versions/1.8/bin/rake"
  )
}


#------------------------------------------------------------------------
# QUOTED CONFIG

@test "outputs path to gem executable when not under rails app directory with quoted config" {
  create_executable "1.8" "rake"
  create_Gemfile
  create_bundle_config '' '"'
  create_binstub "rake"

  RBENV_VERSION=1.8 run rbenv-which rake
  assert_success "${RBENV_ROOT}/versions/1.8/bin/rake"
}


@test "outputs path to binstub executable when under railsapp directory with local quoted config" {
  create_executable "1.8" "rake"
  create_Gemfile
  create_bundle_config '' '"'
  create_binstub "rake"

  (
    cd $RAILS_ROOT
    RBENV_VERSION=1.8 run rbenv-which rake
    assert_success "${RAILS_ROOT}/$TEST_BUNDLE_BIN/rake"

    mkdir tmp
    cd tmp

    RBENV_VERSION=1.8 run rbenv-which rake
    assert_success "${RAILS_ROOT}/$TEST_BUNDLE_BIN/rake"
  )
}

@test "outputs path to binstub executable when under railsapp directory with global quoted config" {
  create_executable "1.8" "rake"
  create_Gemfile
  create_global_bundle_config '"'
  create_binstub "rake"

  (
    cd $RAILS_ROOT
    RBENV_VERSION=1.8 run rbenv-which rake
    assert_success "${RAILS_ROOT}/$TEST_BUNDLE_BIN/rake"

    mkdir tmp
    cd tmp

    RBENV_VERSION=1.8 run rbenv-which rake
    assert_success "${RAILS_ROOT}/$TEST_BUNDLE_BIN/rake"
  )
}

@test "requires Gemfile to find binstub executable with quoted config" {
  create_executable "1.8" "rake"
  create_bundle_config '' '"'
  create_binstub "rake"

  (
    cd $RAILS_ROOT
    RBENV_VERSION=1.8 run rbenv-which rake
    assert_success "${RBENV_ROOT}/versions/1.8/bin/rake"
  )
}

#------------------------------------------------------------------------
# OTHER TESTS

@test "outputs path to binstub executable when under railsapp directory with env config" {
  create_executable "1.8" "rake"
  create_Gemfile
  create_binstub "rake"

  (
    cd $RAILS_ROOT
    BUNDLE_BIN=$TEST_BUNDLE_BIN RBENV_VERSION=1.8 run rbenv-which rake
    assert_success "${RAILS_ROOT}/$TEST_BUNDLE_BIN/rake"

    mkdir tmp
    cd tmp

    BUNDLE_BIN=$TEST_BUNDLE_BIN RBENV_VERSION=1.8 run rbenv-which rake
    assert_success "${RAILS_ROOT}/$TEST_BUNDLE_BIN/rake"
  )
}

# Standard rbenv tests should still pass ...

@test "outputs path to executable" {
  create_executable "1.8" "ruby"
  create_executable "2.0" "rspec"

  RBENV_VERSION=1.8 run rbenv-which ruby
  assert_success "${RBENV_ROOT}/versions/1.8/bin/ruby"

  RBENV_VERSION=2.0 run rbenv-which rspec
  assert_success "${RBENV_ROOT}/versions/2.0/bin/rspec"
}

@test "searches PATH for system version" {
  create_executable "${RBENV_TEST_DIR}/bin" "kill-all-humans"
  create_executable "${RBENV_ROOT}/shims" "kill-all-humans"

  RBENV_VERSION=system run rbenv-which kill-all-humans
  assert_success "${RBENV_TEST_DIR}/bin/kill-all-humans"
}

@test "version not installed" {
  create_executable "2.0" "rspec"
  RBENV_VERSION=1.9 run rbenv-which rspec
  assert_failure "rbenv: version \`1.9' is not installed"
}

@test "no executable found" {
  create_executable "1.8" "rspec"
  RBENV_VERSION=1.8 run rbenv-which rake
  assert_failure "rbenv: rake: command not found"
}

@test "executable found in other versions" {
  create_executable "1.8" "ruby"
  create_executable "1.9" "rspec"
  create_executable "2.0" "rspec"

  RBENV_VERSION=1.8 run rbenv-which rspec
  assert_failure
  assert_output <<OUT
rbenv: rspec: command not found

The \`rspec' command exists in these Ruby versions:
  1.9
  2.0
OUT
}

@test "carries original IFS within hooks" {
  hook_path="${RBENV_TEST_DIR}/rbenv.d"
  mkdir -p "${hook_path}/which"
  cat > "${hook_path}/which/hello.bash" <<SH
hellos=(\$(printf "hello\\tugly world\\nagain"))
echo HELLO="\$(printf ":%s" "\${hellos[@]}")"
exit
SH

  RBENV_HOOK_PATH="$RBENV_HOOK_PATH:$hook_path" IFS=$' \t\n' run rbenv-which anything
  assert_success
  assert_output "HELLO=:hello:ugly:world:again"

}
