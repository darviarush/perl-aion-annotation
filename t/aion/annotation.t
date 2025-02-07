use common::sense; use open qw/:std :utf8/;  use Carp qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  BEGIN {     $SIG{__DIE__} = sub {         my ($s) = @_;         if(ref $s) {             $s->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $s;             die $s;         } else {             die Carp::longmess defined($s)? $s: "undef"         }     };      my $t = File::Slurper::read_text(__FILE__);     my $s =  '/tmp/.liveman/perl-aion-annotation/aion!annotation'    ;     File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $s), File::Path::rmtree($s) if -e $s;     File::Path::mkpath($s);     chdir $s or die "chdir $s: $!";      while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) {         my ($file, $code) = ($1, $2);         $code =~ s/^#>> //mg;         File::Path::mkpath(File::Basename::dirname($file));         File::Slurper::write_text($file, $code);     }  } # 
# # NAME
# 
# Aion::Annotation - обрабатывает аннотации в модулях perl
# 
# # VERSION
# 
# 0.0.0-prealpha
# 
# # SYNOPSIS
# 
# Файл lib/For/Test.pm:
#@> lib/For/Test.pm
#>> package For::Test;
#>> 
#>> #@TODO add1
#>> # Is property
#>> has abc => (is => 'ro');
#>> 
#>> # Is method
#>> 
#>> #@TODO add2
#>> 
#>> #@deprecated
#>> 
#>> #   and subroutine
#>> sub xyz {}
#>> 
#>> sub any {}
#>> 
#>> 1;
#@< EOF
# 
# Файл .config:
#@> .config
#>> config Aion::Annotation => (
#>> 	ON => {
#>> 		deprecated => 'My#on_deprecated',
#>> 		DOTO => 'My#on_todo',
#>> 	},
#>> 	ON_END_MODULE => 'My#on_end_module',
#>> 	ON_END => 'My#on_end'
#>> );
#@< EOF
# 
# Файл lib/My.pm:
#@> lib/My.pm
#>> package My;
#>> 
#>> sub on_deprecated {
#>> 	my ($ann, $attr) = @_;
#>> 	push our @deprecated, "* $ann->{name} ($ann->{type}) in $ann->{pkg}: $ann->{remark}";
#>> }
#>> 
#>> sub on_todo {
#>> 	my ($ann, $attr) = @_;
#>> 	push our @todo, "* $ann->{name} - $attr";
#>> }
#>> 
#>> sub on_end_module {
#>> 	my ($annotation_href, $path) = @_;
#>> 	push our @list_modules, "* $path\n";
#>> }
#>> 
#>> sub on_end {
#>> 	my ($annotations, $paths) = @_;
#>> 	our $count_entities = @$annotations;
#>> }
#>> 
#>> 1;
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
use Aion::Annotation;

Aion::Annotation->scan_project;


my $deprecated = ['* xyz (sub) in My: Is method
  and subroutine
'];

::is_deeply scalar do {\@My::deprecated}, scalar do {$deprecated}, '\@My::deprecated  # --> $deprecated';


my $todo = [
	"* abc - add1",
	"* xyz - add2",
];

::is_deeply scalar do {\@My::todo}, scalar do {$todo}, '\@My::todo  # --> $todo';


my $list_modules = [
	'* lib/My.pm',
	'* lib/My.pm',
	'* lib/My.pm',
];

::is_deeply scalar do {\@My::list_modules}, scalar do {$list_modules}, '\@My::list_modules  # --> $list_modules';


::is scalar do {$My::count_entities}, scalar do{3}, '$My::count_entities  # -> 3';

# 
# # DESCRIPTION
# 
# Aion::Annotation — .
# 
# # FEATURES
# 
# ## path
# 
# Путь к файлу у которого нужно считать аннотации.
# 
done_testing; }; subtest 'path' => sub { 
my $aion_annotation = Aion::Annotation->new(path => 'lib/My.pm');

::is scalar do {$aion_annotation->path}, "lib/My.pm", '$aion_annotation->path	# => lib/My.pm';

# 
# ## annotation
# 
# Хеш всех свойств и подпрограмм в файле с их аннотациями и комментариями.
# 
done_testing; }; subtest 'annotation' => sub { 
my $aion_annotation = Aion::Annotation->new(path => 'lib/My.pm')->scan;

my $annotation = {
};

::is_deeply scalar do {$aion_annotation->annotation}, scalar do {$annotation}, '$aion_annotation->annotation	# --> $annotation';

# 
# # SUBROUTINES/METHODS
# 
# ## scan ()
# 
# Сканирует файл и достаёт все аннотации и комментарии.
# 
done_testing; }; subtest 'scan ()' => sub { 
my $aion_annotation = Aion::Annotation->new(path => 'lib/My.pm')->scan;
::is scalar do {keys %{ $aion_annotation->annotation }}, scalar do{3}, 'keys %{ $aion_annotation->annotation }  # -> 3';

# 
# ## scan_project (@lib)
# 
# Сканирует каталоги с модулями и вызывает на установленные аннотации обработчики.
# 
done_testing; }; subtest 'scan_project (@lib)' => sub { 
undef $My::count_entities;

Aion::Annotation->scan_project("lib");

::is scalar do {$My::count_entities}, scalar do{3}, '$My::count_entities # -> 3';

# 
# # AUTHOR
# 
# Yaroslav O. Kosmina <dart@cpan.org>
# 
# # LICENSE
# 
# ⚖ **GPLv3**
# 
# # COPYRIGHT
# 
# The Aion::Annotation module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

	done_testing;
};

done_testing;
