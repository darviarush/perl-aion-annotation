package Aion::Annotation;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.0-prealpha";

use Aion;

# Путь к файлу
has path => (is => 'ro', isa => Str);

# Хеш: определение => { annotation => { АННОТАЦИЯ => [аннотация1, аннотация2...]}, type => 'sub|has', remark => '...' }
has annotation => (is => 'ro', isa => Hash[Dict[
	annotation => HashRef[Str],
	type => Enum[qw/sub has/],
	remark => MayBe[Str],
]]);


# Сканирует файл и достаёт все аннотации и комментарии
sub scan {
	my ($self) = @_;

	open my $f, "<:utf8", $self->path or die "$self->{path}: $!";
	
	my %ann; my @rem;
	while(<$f>) {
		push @{$ann{$1}}, $2 if /^#\@(\S+)\s*(.*?)\s*$/;
		push @rem, $_ if /^#\s/;
		@rem = %ann = () if /^\}/;
		$self->{annotation}{$2} = {
			annotation => {%ann},
			remark => scalar @rem? join("", map s/^#\s//, @rem): undef,
			type => $1,
		}, @rem = %ann = () if /^(sub|has)\s+(\w+)/;
	}
	
	close $f;
	
	$self
}

1;
