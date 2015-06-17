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
  my $q=$self->param('q');
  my $dat=getAll('jg',"select i.id,i.type_id,i.name,i.descr,t.name as type,i.img ,avg(c.price) as price,sum(c.count) as cnt from items i
    join items_types t on t.id=i.type_id 
    left join items_current c on i.id=c.item_id
    
    where i.name ilike '%$q%' and c.price >0
group by i.type_id,i.name,i.descr,t.name,i.img,i.id
    limit 10");



  $dta = {
   success=>"true",
   results=>{
    c0=>{
      name=> "other",
      results=>[]
    },
    c1=>{
      name=> "copacitors",
      results=>[]
    },
    c2=>{
      name=> "ecm",
      results=>[] 
    },
    c3=>{
      name=> "engines",
      results=>[] 
    },
    c4=>{
      name=> "commodities",
      results=>[] 
    },
    c5=>{
      name=> "shields",
      results=>[] 
    },
    c6=>{
      name=> "guns",
      results=>[] 
    },
    c7=>{
      name=> "missiles",
      results=>[] 
    },
    c8=>{
      name=> "modx",
      results=>[] 
    },
    c9=>{
      name=> "powerplants",
      results=>[] 
    },
    c10=>{
      name=> "radar",
      results=>[] 
    }
   }
  };

            # 'mass' => 180000,
            # 'descr' => 'T&P doesn\'t mess around.  They decided to make a small, light, yet effective rocket and this is it.  It doesn\'t promise to do massive damage, but any ship can carry quite a few of them, and you won\'t need to sell your children for the price.',
            # 'size' => 1,
            # 'name' => 'Spear',
            # 'id' => 47,
            # 'type_id' => 7,
            # 'img' => 'item0.gif'
 foreach my $l (@$dat) {
  push $dta->{results}{"c$l->{type_id}"}{results}, ({title=>$l->{name},
    description=>$l->{cnt},
    url=>"/item/$l->{id}",
    image=>"www/$l->{type}/media/large/$l->{img}",
    price=>"c".int($l->{price})
    });
  }
   print Dumper($dta);

  $self->render(json => $dta);
}

1;
