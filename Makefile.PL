use inc::Module::Install;
perl_version '5.008001';

name           'EWS-Client';
all_from       'lib/EWS/Client.pm';

requires       'Moose'  => '0';
requires       'MooseX::Iterator'  => '0';
requires       'XML::Compile::SOAP'  => '0';
requires       'DateTime'  => '0';
requires       'DateTime::Format::ISO8601'  => '0';
requires       'HTML::Strip'  => '0';
requires       'URI::Escape'  => '0';
requires       'File::ShareDir'  => '0';
requires       'List::MoreUtils'  => '0';

install_share;

WriteAll;
