
use strict;
use warnings;


my $VVV = $ENV{MODULE_VERSION};
my $DEV="";

  $DEV=sprintf "_%04d", $ENV{BUILD_NUMBER}%1000 if ($ENV{BUILD_NUMBER});

s|our\s*\$VERSION\s*=\s*[^;]+;|our \$VERSION = "$VVV$DEV";|;
