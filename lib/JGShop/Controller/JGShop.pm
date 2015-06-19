package JGShop::Controller::JGShop;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON qw (encode_json decode_json true false);
use Adb;
use Data::Dumper;

sub main {
  my $self = shift;
  $self->render();
}

sub search {
  my $self = shift;
  my $dta;
  my $q   = $self->param('q');
  my $dat = getAll(
    'jg',
    "select i.id,i.type_id,i.name,i.descr,t.name as type,i.img ,avg(c.price) as price,sum(c.count) as cnt from items i
    join items_types t on t.id=i.type_id 
    left join items_current c on i.id=c.item_id
    
    where i.name ilike '%$q%' and c.price >0
    group by i.type_id,i.name,i.descr,t.name,i.img,i.id
    limit 10"
  );

  $dta = {
    success => "true",
    results => {
      c0 => {
        name    => "other",
        results => []
      },
      c1 => {
        name    => "copacitors",
        results => []
      },
      c2 => {
        name    => "ecm",
        results => []
      },
      c3 => {
        name    => "engines",
        results => []
      },
      c4 => {
        name    => "commodities",
        results => []
      },
      c5 => {
        name    => "shields",
        results => []
      },
      c6 => {
        name    => "guns",
        results => []
      },
      c7 => {
        name    => "missiles",
        results => []
      },
      c8 => {
        name    => "modx",
        results => []
      },
      c9 => {
        name    => "powerplants",
        results => []
      },
      c10 => {
        name    => "radar",
        results => []
      }
    }
  };

  foreach my $l (@$dat) {
    my $size = 'large';
    if ( $l->{type_id} == 4 ) { $size = 'small' }
    my $price = int( $l->{price} );
    $price =~ s/(\d{3})$/ $1/g;
    $price =~ s/(\d{3}) / $1 /g;

    push $dta->{results}{"c$l->{type_id}"}{results},
      (
      {
        title       => $l->{name},
        description => $l->{cnt},
        url         => "/item/$l->{id}",
        image       => "/www/$l->{type}/media/$size/$l->{img}",
        price       => "c $price"
      }
      );
  }

  $self->render( json => $dta );
}

sub item {
  my $self = shift;

  my $id   = $self->param('item');
  if ($id!~/^\d+$/) {$self->render(text=>'error');return 0}
  my $item = getFirstRow( 'jg',
    "select i.*,t.name as type  from items i join items_types t on t.id=i.type_id where i.id=$id" );
  my $is = getAll( 'jg',
    "select iis.name, s.value from items i ,specs s,items_specs iis where s.item_id=i.id and iis.type_id =i.type_id and s.spec_id=iis.id and i.id=$id"
  );
  my $prod =getAll('jg','select c.item_id as id, i.name, c.contain_id as cid from items i join items_contains c on c.item_id=i.id');
  my $chash;
  foreach my $l (@$prod) {
    $chash->{$l->{cid}}{$l->{name}}=$l->{id};
  } 
  $prod = getAll(
    'jg',
    "select s.name,sum(c.count) as cnt from items_prods p
        LEFT JOIN items_current c ON c.item_id=p.id
        INNER JOIN stations s ON p.station_id=s.id and c.station_id=s.id
        where p.id =$id group by s.name"
  );
  my $cont=getAll('jg',"select
                i.id,i.name as iname, s.id as sid,s.name as station,i.name as item,ic.count as cc,to_char(price,'9999999999999') as price,
                 (select count(*) from items_contains, items_prods where items_contains.item_id=items_prods.id and items_prods.station_id=s.id and contain_id=$id) as need
                        from items i
                        LEFT JOIN items_types t ON t.id=i.type_id
                        LEFT JOIN items_current ic ON i.id=ic.item_id
                        LEFT JOIN stations s ON ic.station_id=s.id

                        where i.id=$id
                        order by s.name");
  $self->render( item => $item, spec => $is,prod=>$prod,cont=>$cont,chash=>$chash);
}

1;
