package PBS::Bootstrap; 

# pragma 
use autodie; 

# core 
use File::Path qw(rmtree); 

# cpan 
use Moose::Role;  
use namespace::autoclean; 

# features 
use experimental qw(signatures); 

# <attributes>
has 'bootstrap', ( 
    is        => 'ro', 
    isa       => 'Str', 
    lazy      => 1,   
    init_arg  => undef, 

    default   => sub ( $self ) { 
        my $bootstrap; 
        my $init_dir = $self->init; 
        
        if ( $self->owner eq $ENV{USER} ) { 
            $bootstrap = ( grep { -d and /bootstrap-\d+/ } glob "$init_dir/*" )[0]; 
        }

        return $bootstrap //= ''; 
    },    
); 

# <methods> 
# remove bootstrap directory after job deletion
sub clean ( $self ) { 
    if ( $self->bootstrap ) { 
        rmtree $self->bootstrap; 
    } 
} 

1; 
