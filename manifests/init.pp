# Class: users
# ===========================
#
# Manageds users and groups
#
# Parameters
# ----------
#
# * `user_hash`
#   A hash of user(s) and properties to create user accounts from
#
# * `login_defs_file`
#   Absolute path to login.defs file
#    default: /etc/login.defs
#
# * `uid_min`
#   Set's the minimum UID to start adding users at 
#    default: 1000
#
# * `gid_min`
#   Set's the minimum GID to start adding groups at 
#    default: 1000
#
class users (
  $user_hash       = hiera_hash('users::user_hash', undef),
  $group_hash      = hiera_hash('users::group_hash', undef),
  $login_defs_file = hiera('users::login_defs_file',
                           $users::params::login_defs_file),
  $uid_min         = hiera('users::uid_min',
                           $users::params::uid_min),
  $gid_min         = hiera('users::gid_min',
                           $users::params::gid_min)
) inherits users::params {

  # validate parameters here
  if $user_hash {
    validate_hash($user_hash)
  }
  if $group_hash {
    validate_hash($group_hash)
  }
  if $login_defs_file {
    validate_absolute_path($login_defs_file)
  }
  if $uid_min {
    validate_integer($uid_min)
  }
  if $gid_min {
    validate_integer($gid_min)
  }

  # set linux minimum uid/gid if values found in hiera
  if ($login_defs_file != undef) and ($uid_min != undef) and ($gid_min != undef) {
    exec { 'modify_login_defs_uid_min':
      command => "sed -ri \'s/^#?(UID_MIN\\s*)([0-9]*)$/\\1${uid_min}/g\' ${login_defs_file}",
      unless  => "grep -q \'^UID_MIN\\s*${uid_min}\$\' ${login_defs_file}",
      path    => ['/bin', '/usr/bin'],
    }
    exec { 'modify_login_defs_gid_min':
      command => "sed -ri \'s/^#?(GID_MIN\\s*)([0-9]*)$/\\1${gid_min}/g\' ${login_defs_file}",
      unless  => "grep -q \'^GID_MIN\\s*${gid_min}\$\' ${login_defs_file}",
      path    => ['/bin', '/usr/bin'],
    }
  }

  # $user_hash comes from hiera data
  if $user_hash {
    $user_hash.each |String $username, Hash $user| {
      validate_string($username)
      validate_string($user['comment'])
      validate_string($user['home'])
      validate_string($user['password'])
      if $user['groups'] {
        validate_array($user['groups'])
      }
      if $user['sudo_commands'] {
        validate_array($user['sudo_commands'])
      }
      $manage_home = true
      if $user['home'] {
        $user_home = $user['home']
      }
      else {
        $user_home = "/home/${username}"
      }
      $purge_keys = true
      $password = undef
      # replace above line with the below line if we want to add linux user passwords. >:-(
      #$password = sha1($user['password'])
      # create user
      user { $username:
        ensure         => present,
        comment        => $user['comment'],
        groups         => $user['groups'],
        password       => $password,
        home           => $user_home,
        managehome     => $manage_home,
        purge_ssh_keys => $purge_keys,
      }
      # manage optional ssh authorized_keys file
      if $user['ssh_authorized_keys'] {
        $user['ssh_authorized_keys'].each |String $key_comment, Hash $auth_key| {
          # prepend the username to the key name to prevent potential duplicates
          ssh_authorized_key { "${username}_${key_comment}":
            user    => $username,
            type    => $auth_key['type'],
            key     => $auth_key['key'],
            require => User[$username],
          }
        }
      }
      # manage optional sudoers file
      if $user['sudo_commands'] {
        $sudo_cmd_str = join($user['sudo_commands'], ', ')
        $sudoers_file = "/etc/sudoers.d/${username}"
        file { $sudoers_file:
          ensure  => present,
          content => "${username} ALL=(ALL) NOPASSWD: ${sudo_cmd_str}\n",
          owner   => root,
          group   => root,
          mode    => '0440',
          notify  => Exec["visudo syntax check of ${sudoers_file}"],
        }
        exec { "visudo syntax check of ${sudoers_file}":
          command     => "rm -f ${sudoers_file}; exit 1",
          unless      => "visudo -cf ${sudoers_file}",
          path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
          refreshonly => true,
        }
      }
    }
  }

  # Any group hash passed had better align with the group resource props!
  if $group_hash {
    create_resources(group, $group_hash)
  }

}
