!ru:en
# NAME

Aion::Annotation - обрабатывает аннотации в модулях perl

# VERSION

0.0.0-prealpha

# SYNOPSIS

Файл lib/For/Test.pm:
```perl
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
```

Файл .config:
```perl
config Aion::Annotation => (
	ON => {
		deprecated => 'My#on_deprecated',
		DOTO => 'My#on_todo',
	},
	ON_END_MODULE => 'My#on_end_module',
	ON_END => 'My#on_end'
);
```

Файл lib/My.pm:
```perl
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
```

```perl
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
```

# DESCRIPTION

Aion::Annotation — .

# FEATURES

## path

Путь к файлу у которого нужно считать аннотации.

```perl
my $aion_annotation = Aion::Annotation->new(path => 'lib/My.pm');

$aion_annotation->path	# => lib/My.pm
```

## annotation

Хеш всех свойств и подпрограмм в файле с их аннотациями и комментариями.

```perl
my $aion_annotation = Aion::Annotation->new(path => 'lib/My.pm')->scan;

my $annotation = {
};

$aion_annotation->annotation	# --> $annotation
```

# SUBROUTINES/METHODS

## scan ()

Сканирует файл и достаёт все аннотации и комментарии.

```perl
my $aion_annotation = Aion::Annotation->new(path => 'lib/My.pm')->scan;
keys %{ $aion_annotation->annotation }  # -> 3
```

## scan_project (@lib)

Сканирует каталоги с модулями и вызывает на установленные аннотации обработчики.

```perl
undef $My::count_entities;

Aion::Annotation->scan_project("lib");

$My::count_entities # -> 3
```

# AUTHOR

Yaroslav O. Kosmina <dart@cpan.org>

# LICENSE

⚖ **GPLv3**

# COPYRIGHT

The Aion::Annotation module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.
