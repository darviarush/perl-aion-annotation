#requires 'perl', '5.22.0';

on 'develop' => sub {
    requires 'Minilla', 'v3.1.19';
    requires 'Data::Printer', '1.000004';
    requires 'Liveman', '1.0';
};

on 'test' => sub {
	requires 'Test::More', '0.98';
};

requires 'common::sense', '3.75';
requires 'config', '0';
requires 'diagnostics', '0';
requires 'feature', '0';
requires 'strict', '0';
requires 'warnings', '1.70';
requires 'Aion', '0';
requires 'Aion::Annotation', '0';
requires 'Aion::Fs', '0';
requires 'PerlIO', '0';
requires 'PerlIO::scalar', '0';
