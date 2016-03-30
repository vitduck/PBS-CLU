package Job; 

use strict; 
use warnings; 
use Carp qw/croak/; 
use IO::Pipe; 

use Queue; 

# constructor
sub new { 
    my ( $class, $id ) = @_; 
    
    # bless ref
    my $self = { id => $id };   
    bless $self => $class; 

    # init
    $self->_init($id);  

    return $self; 
}

# initializer 
sub _init {  
    my ( $self, $id ) = @_; 

    # pipe to qstat 
    my $qstat = IO::Pipe->new(); 
    $qstat->reader("qstat -f $id"); 

    while ( <$qstat> ) { 
        if ( /job_name = (.*)/i )               { $self->{name}     = $1 }   
        if ( /job_owner = (.*)@/i )             { $self->{owner}    = $1 }
        if ( /server = (.*)/i )                 { $self->{server}   = $1 } 
        if ( /job_state = (Q|R)/i )             { $self->{state}    = $1 } 
        if ( /queue = (.*)/i )                  { $self->{queue}    = $1 } 
        if ( /resource_list.nodes = (.*)/i )    { $self->{nodes}    = $1 } 
        if ( /resource_list.walltime = (.*)/i ) { $self->{walltime} = $1 }  
        if ( /init_work_dir = (.*)/i )          { 
            # single line 
            $self->{init_dir} = $1;  
            # broken line 
            chomp ( my $broken = <$qstat> );  
            if ( $broken ) { 
                # trim leading white space 
                $broken =~ s/^\s+//; 
                # join broken part 
                $self->{init_dir} .= $broken; 
            }
        } 
    }
    $qstat->close; 

    # elap time 
    my $queue = Queue->new();  
    $self->{elaptime} = $queue->get_elaptime($id);  

    return; 
}

# job info 
sub info { 
    my ( $self ) = @_; 

    printf "\n"; 
    printf "ID       > %s\n", $self->get_id; 
    printf "Name     > %s\n", $self->get_name;  
    printf "Owner    > %s\n", $self->get_owner;  
    printf "Queue    > %s\n", $self->get_queue; 
    printf "Nodes    > %s\n", $self->get_nodes; 
    printf "Walltime > %s\n", $self->get_walltime; 
    printf "Elaptime > %s\n", $self->get_elaptime; 
    printf "State    > %s\n", $self->get_state; 
    printf "Init_dir > %s\n", $self->get_init_dir; 
    
    return; 
}

# job deletion 
sub delete { 
    my ( $self ) = @_; 
    
    # display job information 
    $self->info();  
    
    # confirmation 
    printf "\n=> qdel: delete job %s? ", $self->get_id;  
    chomp ( my $answer = <STDIN> );  

    # job deletion with qdel 
    if ( $answer =~ /^y/i ) { system 'qdel', $self->get_id }  

    return; 
}

# Assessor with AUTOLOAD 
sub AUTOLOAD { 
    my ( $self ) = @_; 

    # check for valid get_* method 
    our $AUTOLOAD =~/.*::get_(\w+)/ or croak "=> Invalid method: $AUTOLOAD"; 

    # check for valid object attribute
    exists $self->{$1} or croak "=> Invalid attribute: $1";   

    return $self->{$1}; 
}

1; 
