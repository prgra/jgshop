package JGShop::Controller::JGShop;
use Mojo::Base 'Mojolicious::Controller';

sub main {
  my $self = shift;

  $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

1;
