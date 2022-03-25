package Telegram::Bot::Objects::Base;

use Mojo::Base -base;

has '_processor';

sub arrays { qw// }
sub _field_is_array {
  my $self = shift;
  my $field = shift;
  if (grep /^$field$/, $self->arrays) {
    return 1;
  }
  return;
}

sub array_of_arrays { qw// }
sub _field_is_array_of_arrays {
  my $self = shift;
  my $field = shift;
  if (grep /^$field$/, $self->array_of_arrays) {
    return 1;
  }
  return;
}


sub create_from_hash {
  my $class = shift;
  my $hash  = shift;
  my $processor = shift || die "no processor specified";
  my $obj   = $class->new(_processor => $processor);

  foreach my $type (keys %{ $class->fields }) {
    my @fields_of_this_type = @{ $class->fields->{$type} };

    foreach my $field (@fields_of_this_type) {
      next if (! defined $hash->{$field} );
      if ($type eq 'scalar') {
        if ($obj->_field_is_array($field)) {
          my $val = $hash->{$field};
          if (ref($val) eq 'JSON::PP::Boolean') {
            $val = !!$val;
          }
          $obj->$field($val);
        }
        else {
          my $val = $hash->{$field};
          if (ref($val) eq 'JSON::PP::Boolean') {
            $val = 0+$val;
          }
          $obj->$field($val);
        }
      }

      else {
        if ($obj->_field_is_array($field)) {
          my @sub_array;
          foreach my $data ( @{ $hash->{$field} } ) {
            push @sub_array, $type->create_from_hash($data, $processor);
          }
          $obj->$field(\@sub_array);
        }
        else {
          $obj->$field($type->create_from_hash($hash->{$field}, $processor));
        }

      }
    }
  }

  return $obj;
}

sub as_hashref {
  my $self = shift;
  my $hash = {};

  foreach my $type ( keys %{ $self->fields }) {
    my @fields = @{ $self->fields->{$type} };
    foreach my $field (@fields) {

      if ($type eq 'scalar') {

        $hash->{$field} = $self->$field
          if defined $self->$field;
      }
      else {
        if ($self->_field_is_array($field)) {
          next if (! defined $self->$field);
          $hash->{$field} = [
            map { $_->as_hashref } @{ $self->$field }
          ];
        }
        elsif ($self->_field_is_array_of_arrays($field)) {
          next if (! defined $self->$field);
          my $a_of_a = [];
          foreach my $outer ( @{ $self->$field } ) {
            my $inner = [ map { $_->as_hashref } @$outer ];
            push @$a_of_a, $inner;
          }
          $hash->{$field} = $a_of_a;
        }
        else {
          if (defined $self->$field) {
            my $hashref = $self->$field->as_hashref;
            $hash->{$field} = $hashref
              unless ! $hashref;
          }
        }
      }
    }
  }
  return $hash;
}

1;