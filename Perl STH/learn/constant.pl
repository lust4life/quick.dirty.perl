use strict;
use warnings;
use diagnostics;
use 5.20.1;

use constant SPEED_OF_LIGHT => 299_792_458; # m/s

say "the speed of light is :",SPEED_OF_LIGHT;
use constant SPEED_OF_LIGHT => 300_000_000; # m/s
say "the new speed of light is :",SPEED_OF_LIGHT;

use constant DATA => {
   Mercury => [0.4,     0.055   ],
   Venus   => [0.7,     0.815   ],
   Earth   => [1,       1       ],
   Mars    => [1.5,     0.107   ],
   Ceres   => [2.77,    0.00015 ],
   Jupiter => [5.2,   318       ],
   Saturn  => [9.5,    95       ],
   Uranus  => [19.6,   14       ],
   Neptune => [30,     17       ],
   Pluto   => [39,   0.00218    ],
   Charon  => [39,   0.000254   ],
};
use constant PLANETS => [ sort keys %{ DATA() } ];
say join ', ', @{ PLANETS() };
${PLANETS()}[0] = 'Lust4Life';
say join ', ', @{ PLANETS() };  # 仍然会改变值， constant 的作用是针对这个引用的值不能改变(引用地址不能)，而这个值所指向的具体内容是可以改变的(引用地址所指向的内容可以改变)。
