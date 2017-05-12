# Class: rabbitmq::repo::rhel
# Makes sure that the Packagecloud repo is installed
class rabbitmq::repo::rhel(
    $location       = 'https://packagecloud.io/rabbitmq/rabbitmq-server/el/$releasever/$basearch',
    $key_source     = 'https://www.rabbitmq.com/rabbitmq-release-signing-key.asc',
  ) {

  Class['rabbitmq::repo::rhel'] -> Package<| title == 'rabbitmq-server' |>

  if $rabbitmq::erlang_source == 'rabbitmq' {
    yumrepo { 'rabbitmq_erlang':
      ensure  => present,
      name    => 'rabbitmq_erlang',
      baseurl => 'https://packagecloud.io/rabbitmq/erlang/el/$releasever/$basearch',
      enabled => 1
    }
  }

  yumrepo { 'rabbitmq':
    ensure  => present,
    name    => 'rabbitmq_rabbitmq-server',
    baseurl => $location,
    gpgkey  => $key_source,
    enabled => 1,
  }
}
