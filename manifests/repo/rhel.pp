# Class: rabbitmq::repo::rhel
# Makes sure that the Packagecloud repo is installed
class rabbitmq::repo::rhel(
    $location       = 'https://packagecloud.io/rabbitmq/rabbitmq-server/el/$releasever/$basearch',
    $key_source     = 'https://www.rabbitmq.com/rabbitmq-release-signing-key.asc',
  ) {

  Class['rabbitmq::repo::rhel'] -> Package<| title == 'rabbitmq-server' |>

  yumrepo { 'rabbitmq':
    ensure  => present,
    name    => 'rabbitmq_rabbitmq-server',
    baseurl => $location,
    gpgkey  => $key_source,
    enabled => 1,
  }
}
