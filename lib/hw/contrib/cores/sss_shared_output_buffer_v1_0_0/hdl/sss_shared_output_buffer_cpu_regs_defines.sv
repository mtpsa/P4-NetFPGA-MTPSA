`define  REG_ID_BITS                    31:0
`define  REG_ID_WIDTH                   32
`define  REG_ID_DEFAULT                 32'h0000DA03
`define  REG_ID_ADDR                    32'h0

`define  REG_VERSION_BITS               31:0
`define  REG_VERSION_WIDTH              32
`define  REG_VERSION_DEFAULT            32'h1
`define  REG_VERSION_ADDR               32'h4

`define  REG_RESET_BITS                 15:0
`define  REG_RESET_WIDTH                16
`define  REG_RESET_DEFAULT              16'h0
`define  REG_RESET_ADDR                 32'h8

`define  REG_FLIP_BITS                  31:0
`define  REG_FLIP_WIDTH                 32
`define  REG_FLIP_DEFAULT               32'h0
`define  REG_FLIP_ADDR                  32'hC

`define  REG_DEBUG_BITS                 31:0
`define  REG_DEBUG_WIDTH                32
`define  REG_DEBUG_DEFAULT              32'h0
`define  REG_DEBUG_ADDR                 32'h10

`define  REG_PKTIN_BITS                 31:0
`define  REG_PKTIN_WIDTH                32
`define  REG_PKTIN_DEFAULT              32'h0
`define  REG_PKTIN_ADDR                 32'h14

`define  REG_PKTOUT_BITS                31:0
`define  REG_PKTOUT_WIDTH               32
`define  REG_PKTOUT_DEFAULT             32'h0
`define  REG_PKTOUT_ADDR                32'h18


`define  REG_PKTSTOREDPORT0_BITS        31:0
`define  REG_PKTSTOREDPORT0_WIDTH       32
`define  REG_PKTSTOREDPORT0_DEFAULT     32'h0
`define  REG_PKTSTOREDPORT0_ADDR        32'h1C

`define  REG_BYTESSTOREDPORT0_BITS      31:0
`define  REG_BYTESSTOREDPORT0_WIDTH     32
`define  REG_BYTESSTOREDPORT0_DEFAULT   32'h0
`define  REG_BYTESSTOREDPORT0_ADDR      32'h20

`define  REG_PKTREMOVEDPORT0_BITS       31:0
`define  REG_PKTREMOVEDPORT0_WIDTH      32
`define  REG_PKTREMOVEDPORT0_DEFAULT    32'h0
`define  REG_PKTREMOVEDPORT0_ADDR       32'h24

`define  REG_BYTESREMOVEDPORT0_BITS     31:0
`define  REG_BYTESREMOVEDPORT0_WIDTH    32
`define  REG_BYTESREMOVEDPORT0_DEFAULT  32'h0
`define  REG_BYTESREMOVEDPORT0_ADDR     32'h28

`define  REG_PKTDROPPEDPORT0_BITS       31:0
`define  REG_PKTDROPPEDPORT0_WIDTH      32
`define  REG_PKTDROPPEDPORT0_DEFAULT    32'h0
`define  REG_PKTDROPPEDPORT0_ADDR       32'h2C

`define  REG_BYTESDROPPEDPORT0_BITS     31:0
`define  REG_BYTESDROPPEDPORT0_WIDTH    32
`define  REG_BYTESDROPPEDPORT0_DEFAULT  32'h0
`define  REG_BYTESDROPPEDPORT0_ADDR     32'h30

`define  REG_PKTINQUEUEPORT0_BITS       31:0
`define  REG_PKTINQUEUEPORT0_WIDTH      32
`define  REG_PKTINQUEUEPORT0_DEFAULT    32'h0
`define  REG_PKTINQUEUEPORT0_ADDR       32'h34

`define  REG_PKTSTOREDPORT1_BITS        31:0
`define  REG_PKTSTOREDPORT1_WIDTH       32
`define  REG_PKTSTOREDPORT1_DEFAULT     32'h0
`define  REG_PKTSTOREDPORT1_ADDR        32'h38

`define  REG_BYTESSTOREDPORT1_BITS      31:0
`define  REG_BYTESSTOREDPORT1_WIDTH     32
`define  REG_BYTESSTOREDPORT1_DEFAULT   32'h0
`define  REG_BYTESSTOREDPORT1_ADDR      32'h3C

`define  REG_PKTREMOVEDPORT1_BITS       31:0
`define  REG_PKTREMOVEDPORT1_WIDTH      32
`define  REG_PKTREMOVEDPORT1_DEFAULT    32'h0
`define  REG_PKTREMOVEDPORT1_ADDR       32'h40

`define  REG_BYTESREMOVEDPORT1_BITS     31:0
`define  REG_BYTESREMOVEDPORT1_WIDTH    32
`define  REG_BYTESREMOVEDPORT1_DEFAULT  32'h0
`define  REG_BYTESREMOVEDPORT1_ADDR     32'h44

`define  REG_PKTDROPPEDPORT1_BITS       31:0
`define  REG_PKTDROPPEDPORT1_WIDTH      32
`define  REG_PKTDROPPEDPORT1_DEFAULT    32'h0
`define  REG_PKTDROPPEDPORT1_ADDR       32'h48

`define  REG_BYTESDROPPEDPORT1_BITS     31:0
`define  REG_BYTESDROPPEDPORT1_WIDTH    32
`define  REG_BYTESDROPPEDPORT1_DEFAULT  32'h0
`define  REG_BYTESDROPPEDPORT1_ADDR     32'h4C

`define  REG_PKTINQUEUEPORT1_BITS       31:0
`define  REG_PKTINQUEUEPORT1_WIDTH      32
`define  REG_PKTINQUEUEPORT1_DEFAULT    32'h0
`define  REG_PKTINQUEUEPORT1_ADDR       32'h50

`define  REG_PKTSTOREDPORT2_BITS        31:0
`define  REG_PKTSTOREDPORT2_WIDTH       32
`define  REG_PKTSTOREDPORT2_DEFAULT     32'h0
`define  REG_PKTSTOREDPORT2_ADDR        32'h54

`define  REG_BYTESSTOREDPORT2_BITS      31:0
`define  REG_BYTESSTOREDPORT2_WIDTH     32
`define  REG_BYTESSTOREDPORT2_DEFAULT   32'h0
`define  REG_BYTESSTOREDPORT2_ADDR      32'h58

`define  REG_PKTREMOVEDPORT2_BITS       31:0
`define  REG_PKTREMOVEDPORT2_WIDTH      32
`define  REG_PKTREMOVEDPORT2_DEFAULT    32'h0
`define  REG_PKTREMOVEDPORT2_ADDR       32'h5C

`define  REG_BYTESREMOVEDPORT2_BITS     31:0
`define  REG_BYTESREMOVEDPORT2_WIDTH    32
`define  REG_BYTESREMOVEDPORT2_DEFAULT  32'h0
`define  REG_BYTESREMOVEDPORT2_ADDR     32'h60

`define  REG_PKTDROPPEDPORT2_BITS       31:0
`define  REG_PKTDROPPEDPORT2_WIDTH      32
`define  REG_PKTDROPPEDPORT2_DEFAULT    32'h0
`define  REG_PKTDROPPEDPORT2_ADDR       32'h64

`define  REG_BYTESDROPPEDPORT2_BITS     31:0
`define  REG_BYTESDROPPEDPORT2_WIDTH    32
`define  REG_BYTESDROPPEDPORT2_DEFAULT  32'h0
`define  REG_BYTESDROPPEDPORT2_ADDR     32'h68

`define  REG_PKTINQUEUEPORT2_BITS       31:0
`define  REG_PKTINQUEUEPORT2_WIDTH      32
`define  REG_PKTINQUEUEPORT2_DEFAULT    32'h0
`define  REG_PKTINQUEUEPORT2_ADDR       32'h6C

`define  REG_PKTSTOREDPORT3_BITS        31:0
`define  REG_PKTSTOREDPORT3_WIDTH       32
`define  REG_PKTSTOREDPORT3_DEFAULT     32'h0
`define  REG_PKTSTOREDPORT3_ADDR        32'h70

`define  REG_BYTESSTOREDPORT3_BITS      31:0
`define  REG_BYTESSTOREDPORT3_WIDTH     32
`define  REG_BYTESSTOREDPORT3_DEFAULT   32'h0
`define  REG_BYTESSTOREDPORT3_ADDR      32'h74

`define  REG_PKTREMOVEDPORT3_BITS       31:0
`define  REG_PKTREMOVEDPORT3_WIDTH      32
`define  REG_PKTREMOVEDPORT3_DEFAULT    32'h0
`define  REG_PKTREMOVEDPORT3_ADDR       32'h78

`define  REG_BYTESREMOVEDPORT3_BITS     31:0
`define  REG_BYTESREMOVEDPORT3_WIDTH    32
`define  REG_BYTESREMOVEDPORT3_DEFAULT  32'h0
`define  REG_BYTESREMOVEDPORT3_ADDR     32'h7C

`define  REG_PKTDROPPEDPORT3_BITS       31:0
`define  REG_PKTDROPPEDPORT3_WIDTH      32
`define  REG_PKTDROPPEDPORT3_DEFAULT    32'h0
`define  REG_PKTDROPPEDPORT3_ADDR       32'h80

`define  REG_BYTESDROPPEDPORT3_BITS     31:0
`define  REG_BYTESDROPPEDPORT3_WIDTH    32
`define  REG_BYTESDROPPEDPORT3_DEFAULT  32'h0
`define  REG_BYTESDROPPEDPORT3_ADDR     32'h84

`define  REG_PKTINQUEUEPORT3_BITS       31:0
`define  REG_PKTINQUEUEPORT3_WIDTH      32
`define  REG_PKTINQUEUEPORT3_DEFAULT    32'h0
`define  REG_PKTINQUEUEPORT3_ADDR       32'h88

`define  REG_PKTSTOREDPORT4_BITS        31:0
`define  REG_PKTSTOREDPORT4_WIDTH       32
`define  REG_PKTSTOREDPORT4_DEFAULT     32'h0
`define  REG_PKTSTOREDPORT4_ADDR        32'h8C

`define  REG_BYTESSTOREDPORT4_BITS      31:0
`define  REG_BYTESSTOREDPORT4_WIDTH     32
`define  REG_BYTESSTOREDPORT4_DEFAULT   32'h0
`define  REG_BYTESSTOREDPORT4_ADDR      32'h90

`define  REG_PKTREMOVEDPORT4_BITS       31:0
`define  REG_PKTREMOVEDPORT4_WIDTH      32
`define  REG_PKTREMOVEDPORT4_DEFAULT    32'h0
`define  REG_PKTREMOVEDPORT4_ADDR       32'h94

`define  REG_BYTESREMOVEDPORT4_BITS     31:0
`define  REG_BYTESREMOVEDPORT4_WIDTH    32
`define  REG_BYTESREMOVEDPORT4_DEFAULT  32'h0
`define  REG_BYTESREMOVEDPORT4_ADDR     32'h98

`define  REG_PKTDROPPEDPORT4_BITS       31:0
`define  REG_PKTDROPPEDPORT4_WIDTH      32
`define  REG_PKTDROPPEDPORT4_DEFAULT    32'h0
`define  REG_PKTDROPPEDPORT4_ADDR       32'h9C

`define  REG_BYTESDROPPEDPORT4_BITS     31:0
`define  REG_BYTESDROPPEDPORT4_WIDTH    32
`define  REG_BYTESDROPPEDPORT4_DEFAULT  32'h0
`define  REG_BYTESDROPPEDPORT4_ADDR     32'hA0

`define  REG_PKTINQUEUEPORT4_BITS       31:0
`define  REG_PKTINQUEUEPORT4_WIDTH      32
`define  REG_PKTINQUEUEPORT4_DEFAULT    32'h0
`define  REG_PKTINQUEUEPORT4_ADDR       32'hA4