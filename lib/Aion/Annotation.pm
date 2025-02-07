package Aion::Annotation;
use 5.22.0;
no strict; no warnings; no diagnostics;
use common::sense;

our $VERSION = "0.0.0-prealpha";

use Aion::Fs qw/find/;

# Обработчики аннотаций
use config ON => {};

# Обработчик на конец обработки каждого модуля
use config ON_END_MODULE => undef;

# Обработчик на конец обработки всех директорий
use config ON_END => undef;

use Aion;

# Путь к файлу
has path => (is => 'ro', isa => Str);

# Хеш: определение => { annotations => [ [АННОТАЦИЯ => аргументы], ...], type => 'sub|has', remark => '...' }
has annotation => (is => 'ro', isa => Hash[Dict[
	annotations => ArrayRef[ArrayRef[Str]],
	name => Str,
	type => Enum[qw/sub has/],
	remark => MayBe[Str],
	pkg => Str,
]]);


# Сканирует файл и достаёт все аннотации и комментарии
sub scan {
	my ($self) = @_;

	open my $f, "<:utf8", $self->{path} or die "$self->{path}: $!";
	
	my $pkg = 'main'; my @ann; my @rem;
	while(<$f>) {
		push @ann, [$1, $2] if /^#\@(\S+)\s*(.*?)\s*$/;
		push @rem, $_ if /^#\s/;
		$pkg = $1 if /^package\s+([a-zA-Z_]\w*(?:::[a-zA-Z_]\w*)*)\s*;/a;
		@rem = @ann = () if /^\}/;
		$self->{annotation}{$2} = {
			annotations => [@ann],
			pkg => $pkg,
			name => $2,
			type => $1,
			remark => scalar @rem? join("", map s/^#\s//, @rem): undef,
		}, @rem = %ann = () if /^(sub|has)\s+(\w+)/;
	}
	
	close $f;
	
	$self
}

# Подгружает процессор и возвращает его функцию
sub _init_processor {
	my ($v, $event) = @_;
	
	die "$event `$v` - not valid!" unless $v =~ /^([\w:]+)#(\w+)$/a;
	eval "require $1" or die;
	my $sub = $v =~ s/#/::/r;
	die "Annotation processor was not detected! $event `$v`." unless *{$sub}{SUB};
	\&$sub
}

# Сканирует каталоги с модулями и вызывает на установленные аннотации обработчики
sub scan_project {
	my ($cls, @lib) = @_;
	
	@lib = 'lib' unless @lib;
	
	my $on_end_module;
	$on_end_module = _init_processor(ON_END_MODULE, "ON_END_MODULE") if ON_END_MODULE;

	my $on_end;
	$on_end = _init_processor(ON_END, "ON_END") if ON_END;
	
	my %on;
	
	# Инициализируем обработчики
	while (my ($k, $v) = each %{ON()}) {
		$on{$k} = _init_processor($v, "ON $k =>");
	}
	
	my @ann;
	my @paths;
	
	# Проходимся по модулям
	find \@lib, "-f", "*.pm", sub {
		my $annotation_href = Aion::Annotation->new(path => $_)->scan->{annotation};
		push @ann, $annotation_href;
		
		for my $name (keys %$annotation_href) {
			my $ann = $annotation_href->{$name};
			
			my $annotations = $ann->{annotations};
			for $annotation (@$annotations) {
				my ($k, $attr) = @$annotation;
				$on{$k}->($ann, $attr) if exists $on{$k};
			}
		}
		
		$on_end_module->($annotation_href, $_) if $on_end_module;
		push @paths, $path;
	0 };
	
	$on_end->(\@ann, \@paths) if $on_end;
	
	$cls
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Annotation - обрабатывает аннотации в модулях perl

=head1 VERSION

0.0.0-Prealpha

=head1 SYNOPSIS

Файл lib/For/Test.pm:

	package For::Test;
	
	#@TODO add1
	# Is property
	has abc => (is => 'ro');
	
	# Is method
	
	#@TODO add2
	
	#@deprecated
	
	#   and subroutine
	sub xyz {}
	
	sub any {}
	
	1;

Файл .config:

	config Aion::Annotation => (
		ON => {
			deprecated => 'My#on_deprecated',
			DOTO => 'My#on_todo',
		},
		ON_END_MODULE => 'My#on_end_module',
		ON_END => 'My#on_end'
	);

Файл lib/My.pm:

	package My;
	
	sub on_deprecated {
		my ($ann, $attr) = @_;
		push our @deprecated, "* $ann->{name} ($ann->{type}) in $ann->{pkg}: $ann->{remark}";
	}
	
	sub on_todo {
		my ($ann, $attr) = @_;
		push our @todo, "* $ann->{name} - $attr";
	}
	
	sub on_end_module {
		my ($annotation_href, $path) = @_;
		push our @list_modules, "* $path\n";
	}
	
	sub on_end {
		my ($annotations, $paths) = @_;
		our $count_entities = @$annotations;
	}
	
	1;



	use Aion::Annotation;
	
	Aion::Annotation->scan_project;
	
	
	my $deprecated = ['* xyz (sub) in My: Is method
	  and subroutine
	'];
	
	\@My::deprecated  # --> $deprecated
	
	
	my $todo = [
		"* abc - add1",
		"* xyz - add2",
	];
	
	\@My::todo  # --> $todo
	
	
	my $list_modules = [
		'* lib/My.pm',
		'* lib/My.pm',
		'* lib/My.pm',
	];
	
	\@My::list_modules  # --> $list_modules
	
	
	$My::count_entities  # -> 3

=head1 Description

Aion::Annotation — .

=head1 FEATURES

=head2 path

Путь к файлу у которого нужно считать аннотации.

	my $aion_annotation = Aion::Annotation->new(path => 'lib/My.pm');
	
	$aion_annotation->path	# => lib/My.pm

=head2 Annotation

Хеш всех свойств и подпрограмм в файле с их аннотациями и комментариями.

	my $aion_annotation = Aion::Annotation->new(path => 'lib/My.pm')->scan;
	
	my $annotation = {
	};
	
	$aion_annotation->annotation	# --> $annotation

=head1 Subrautines/Methods

=head2 scan ()

Сканирует файл и достаёт все аннотации и комментарии.

	my $aion_annotation = Aion::Annotation->new(path => 'lib/My.pm')->scan;
	keys %{ $aion_annotation->annotation }  # -> 3

=head2 Scan_Project (@lib)

Сканирует каталоги с модулями и вызывает на установленные аннотации обработчики.

	undef $My::count_entities;
	
	Aion::Annotation->scan_project("lib");
	
	$My::count_entities # -> 3

=head1 Author

Yaroslav O. kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Annotation module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

