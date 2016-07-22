# == Class jamwiki::params
#
# This class is meant to be called from jamwiki.
# It sets same default paramaters.
#
class users::params {
  case $osfamily {
    'Debian': {
      $uid_min = 1000
      $gid_min = 1000
      $login_defs_file = '/etc/login.defs'
    }
    'RedHat', 'Amazon': {
      $uid_min = 1000
      $gid_min = 1000
      $login_defs_file = '/etc/login.defs'
    }
    'Windows': {
    }
    default: {
      fail("${operatingsystem} not supported")
    }
  }
}
