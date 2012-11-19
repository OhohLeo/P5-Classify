sub scan_dir {
  my ($path, $filter, $cb) = @_;
  my (@queue, @matches);
  my $cv = AE::cv;

  my $enqueue = sub {
    $cv->begin;
    push @queue, shift;
  };

  $enqueue->($path);

  my $scan = sub {
    my $path = shift;
    aio_scandir $path, 0, sub {
      my ($dirs, $nondirs) = @_;
      for (@$nondirs) {
        push @matches, "$path/$_" if $filter->("$path/$_");
      }
      $enqueue->("$path/$_") for @$dirs;
      $cv->end;
    };
  };

  my $t = AE::idle sub {
    if (my $dir = pop @queue) {
      $scan->($dir);
    }
  };

  $cv->cb(sub {
    eval {shift->recv};
    undef $t;
    if ($@) {
      warn "scanner stopped";
      return;
    }
    $cb->(\@matches);
  });

  return $cv;
}
