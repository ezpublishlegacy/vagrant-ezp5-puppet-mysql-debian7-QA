include upgrade
include ntpd
include motd
include apachephp
include imagick
include db
include apc
include createdb
include ezfind
include virtualhosts
include composer
include prepareezpublish
include addhosts
include xdebug
include acl
include git
## QA ##
include svn
include ssh
include ftp
include ezsi
include tests
include vncserver
include seleniumstuffserver
include fixupdatedb
## QA ##


#### QA ####
class svn {
    require upgrade
    package { "subversion":
        ensure => installed,
    } ~>
    file { "/home/vagrant/.subversion":
        ensure => "directory",
        owner  => "vagrant",
        group  => "vagrant",
        mode   => '750',  
    } 
    file { "/home/vagrant/.subversion/config":
        ensure => file,
        content => template('/tmp/vagrant-puppet/manifests/svn/config.erb'),
        owner   => 'vagrant',
        group   => 'vagrant',
        mode    => '750',
    }
}

class ssh {
    require upgrade
    file { "/etc/ssh/sshd_config":
        ensure => file,
        content => template('/tmp/vagrant-puppet/manifests/ssh/sshd_config.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
    }
}

class ftp {
    require upgrade    
    $neededpackages = ["vsftpd", "ftp"]
    package { $neededpackages:
        ensure => installed,
    } ~>
#    exec { "setsebool -P ftp_home_dir=1":
#        command => "/usr/sbin/setsebool -P ftp_home_dir=1",
#        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
#        returns => [ 0, 1, '', ' ']
#    } ~>
    service { "vsftpd":
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        require => Package["vsftpd"],
        restart => true;
    }    
}

class ezsi {
    require upgrade    
    user { "esitest":
        comment => "Creating user esitest",
        home => "/home/esitest",
        ensure => present,
        shell => "/bin/bash",
    } ~>
    file { "/home/esitest":
        ensure => "directory",
        owner  => "esitest",
        group  => "esitest",
        mode   => '750',  
    }    
#    file { "/etc/apache2/conf.d/filter.conf":
#        ensure => file,
#        content => template('/tmp/vagrant-puppet/manifests/apache/filter.conf.erb'),
#        owner   => 'root',
#        group   => 'root',
#        mode    => '640',
#    }
}

class tests {
    require upgrade    
    package { "patch":
        ensure => installed,
    } ->
    file { "/usr/local/sbin/restart_apache.sh":
        ensure => file,
        content => template('/tmp/vagrant-puppet/manifests/tests/restart_apache.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '755',
    } ~>
    file { "/usr/local/sbin/rootlaunch":
        ensure => file,
        content => template('/tmp/vagrant-puppet/manifests/tests/rootlaunch.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '755',
    } ~>
    file { "/usr/local/etc/configfile.rootlaunch":
        ensure => file,
        content => template('/tmp/vagrant-puppet/manifests/tests/configfile.rootlaunch.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
    }
}

class vncserver {
    require upgrade    
    $neededpackages = [ "tightvncserver", "xterm", "matchbox-window-manager"]
    package { $neededpackages:
        ensure => present,
    } ~>
    file { "/home/vagrant/.Xauthority":
        ensure => file,
        content => template('/tmp/vagrant-puppet/manifests/vncserver/Xauthority.erb'),
        owner  => "vagrant",
        group  => "vagrant",
        mode   => '750',  
    } ~>
    file { "/home/vagrant/.vnc":
        ensure => "directory",
        owner  => "vagrant",
        group  => "vagrant",
        mode   => '750',  
    } ~>
    file { "/home/vagrant/.vnc/xstartup":
        ensure => file,
        content => template('/tmp/vagrant-puppet/manifests/vncserver/xstartup.erb'),
        owner  => "vagrant",
        group  => "vagrant",
        mode   => '777',  
    }
}

class seleniumstuffserver {
    require upgrade
    exec { "create selenium folder":
        command => "/bin/mkdir /opt/selenium",
        path    => "/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/vagrant/bin",
        returns => [ 0, 1, '', ' ']
    } ~>
    exec    { "wget":
        cwd     => "/opt/selenium",
        command => "/usr/bin/wget http://selenium.googlecode.com/files/selenium-server-standalone-2.35.0.jar",
        path    => "/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/vagrant/bin",
        returns => [ 0, 1, '', ' ']
    } ~>
    file { "/usr/local/bin/start_seleniumrc.sh":
        ensure => file,
        content => template('/tmp/vagrant-puppet/manifests/selenium/start_seleniumrc.sh.erb'),
        mode   => '777',  
    } ~>
    exec    { "chmod":
        command => "/bin/chmod +x /user/local/bin/start_seleniumrc.sh",
        path    => "/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/vagrant/bin",
        returns => [ 0, 1, '', ' ']
    } ~>
    exec { "wget firefox":
        command => "/usr/bin/wget 'http://ftp.mozilla.org/pub/mozilla.org/firefox/releases/23.0.1/linux-x86_64/en-GB/firefox-23.0.1.tar.bz2'",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
        refreshonly => true,
        returns => [ 0, 1]
    } ~>
    exec { "untar firefox":
        command => "/bin/tar -xjf firefox-23.0.1.tar.bz2 -C /opt",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
        refreshonly => true,
    } ~>
    exec { "/bin/ln -s /opt/firefox/firefox":
        command => "/bin/ln -s /opt/firefox/firefox /usr/local/bin/firefox",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
        refreshonly => true,
    } ~>
    package { "firefox-sage":  
        ensure => installed,
    } 
    ## Don't know why, but you need to have firefox from Debian installed without it will give the error:
    ## libdbus-glib-1.so.2: cannot open shared object file: No such file or directory
    ## Couldn't load XPCOM
}

class fixupdatedb {
    require upgrade 
    exec { "update db":
        command => "/usr/bin/updatedb",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
        returns => [ 0, 1, '', ' ']
      }  
}
#### QA ####

class acl {
    require upgrade
    package { "acl":
        ensure => installed,
    } ~>
    file {'/etc/fstab':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/acl/fstab.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644'
    }
}

class xdebug {
    require upgrade
    package { "php5-xdebug":
        ensure => installed,
    } ~>
    file {'/etc/php5/conf.d/xdebug.ini':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/php/xdebug.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => Package["php5"],
    }
}

class git {
    package { "git":
      ensure => installed,
    }
}

class upgrade {
    exec { 'apt-get update':
        command => '/usr/bin/apt-get update',
        returns => [0, 1],
    } ~>
    exec { 'apt-get dist-upgrade':
        command => '/usr/bin/apt-get dist-upgrade -y',
        returns => [0, 1, 100],
    } ~>
    package { "vim":
        ensure => installed,
    }
}

class ntpd {
    require upgrade
    package { "ntpdate": 
        ensure => installed 
    }
}

class motd {
    require upgrade    
    file    {'/etc/motd':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/motd/motd.xdebug.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
    }
}

class apachephp {
    $neededpackages = [ "apache2", "apache2-mpm-prefork", "php5", "php5-cli", "php5-gd" ,"php5-mysql", "php-pear", "php-xml-rpc", "curl", "php5-intl", "php5-curl", "php5-xsl" ]
    require upgrade
    package { $neededpackages:
        ensure => present,
    } ~>
    file    {'/etc/apache2/sites-enabled/01.accept_pathinfo.conf':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/apache/01.accept_pathinfo.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
    } ~>
    file    {'/etc/php5/conf.d/php.ini':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/php/php.ini.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
    } ~>
    exec { "rewrite rules":
        command => "/usr/sbin/a2enmod rewrite",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
        refreshonly => true,
        require => Package[ "apache2" ]
    } ~>
    exec { "restart apache2":
        command => "/usr/sbin/service apache2 restart",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
        returns => [ 0, 1]
    }
}

class imagick {
    require upgrade    
    $neededpackages = [ "imagemagick", "imagemagick-common", "php5-imagick" ]
    require upgrade
    package { $neededpackages:
        ensure => installed
    }
}

class db {
    require upgrade    
    $neededpackages = [ "mysql-client-5.5", "mysql-server-5.5"]
    package { $neededpackages:
        ensure => installed
    } ~>
    service { "mysql":
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        require => Package["mysql-server-5.5"],
        restart => true;
    }
}


class apc {
    require upgrade    
    $neededpackages = [ "php5-dev", "php-apc" ]
    package { $neededpackages:
        ensure => installed
    } ~>
    file    {'/etc/php5/apache2/conf.d/20-apc.ini':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/php/apc.ini.erb'),
    }
}

class createdb {
    require upgrade    
    exec { "create-ezp-db":
        command => "/usr/bin/mysql -uroot -e \"create database ezp character set utf8; grant all on ezp.* to ezp@localhost identified by 'ezp';\"",
        require => Service["mysql"],
        returns => [ 0, 1, '', ' ']
    }
}

class ezfind {
    require upgrade
    package { "openjdk-6-jdk":
        ensure => installed
    }
}

class virtualhosts {
    require upgrade
    file {'/etc/apache2/sites-enabled/02.namevirtualhost.conf':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/virtualhost/02.namevirtualhost.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => Package["apache2"],
    } ~>
    file {'/etc/apache2/sites-enabled/ezp5.conf':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/virtualhost/ezp5.xdebug.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
        require => Package["apache2"],
    } ~>
    exec { "remove 000-default":
        command => "/bin/rm /etc/apache2/sites-enabled/000-default",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
        refreshonly => true,
    }
}

class composer {
    require upgrade    
    exec { "get composer":
        command => "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin",
        path    => "/usr/local/bin:/usr/bin/",
        require => Package["apache2"],
        returns => [ 0, 1, '', ' ']
    } ~>
    exec { "link composer":
        command => "/bin/ln -s /usr/local/bin/composer.phar /usr/local/bin/composer",
        path    => "/usr/local/bin:/usr/bin/:/bin",
        returns => [ 0, 1, '', ' ']
    }
}

class prepareezpublish {
    require upgrade
    require apachephp
    service { 'apache2':
        ensure => running,
        enable => true,
        require => [File['/etc/apache2/sites-enabled/01.accept_pathinfo.conf'], File['/etc/apache2/sites-enabled/ezp5.conf']]
    } ~>
    exec { "Fix owner":
        command => "/bin/chown -R www-data:www-data /var/www/",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
    } ~>
    exec { "Fix Permissions":
        command => "/bin/chmod -R 777 /var/www/",
        path => "/usr/bin:/usr/sbin:/bin:/usr/local/bin",
    }
}

class addhosts {
    require upgrade    
    file {'/etc/hosts':
        ensure  => file,
        content => template('/tmp/vagrant-puppet/manifests/hosts/hosts.xdebug.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '644',
    }
}