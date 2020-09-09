#ifndef SDNET_ENGINE_@MODULE_NAME@
#define SDNET_ENGINE_@MODULE_NAME@

#include "sdnet_lib.hpp"

#define BITMASK_WIDTH (@BITMASK_WIDTH@)
#define PKT_LEN_WIDTH (@PKT_LEN_WIDTH@)
#define INPUT_WIDTH   (BITMASK_WIDTH+PKT_LEN_WIDTH)

namespace SDNET {
    class @MODULE_NAME@ { // UserEngine
        public:
            // tuple types
            struct @EXTERN_NAME@_input_t {
                static const size_t _SIZE = INPUT_WIDTH+1;
                _LV<1> stateful_valid;
                _LV<BITMASK_WIDTH> memory_bitmask;
                _LV<PKT_LEN_WIDTH> pkt_len;

                @EXTERN_NAME@_input_t& operator=(_LV<INPUT_WIDTH+1> _x) {
                    stateful_valid = _x.slice(INPUT_WIDTH+1, INPUT_WIDTH);
                    memory_bitmask = _x.slice(INPUT_WIDTH-1, PKT_LEN_WIDTH);
                    pkt_len = _x.slice(PKT_LEN_WIDTH-1, 0);
                    return *this;
                }

                _LV<INPUT_WIDTH+1> get_LV() {
                    return (stateful_valid,memory_bitmask,pkt_len);
                }

                operator _LV<INPUT_WIDTH+1>() {
                    return get_LV();
                }

                std::string to_string() const {
                    return "(\n\t\tstateful_valid = " + stateful_valid.to_string()
                          + "\n\t\tmemory_bitmask = " + memory_bitmask.to_string()
                          + "\n\t\tpkt_len = " + pkt_len.to_string() + "\n\t)";
                }

                @EXTERN_NAME@_input_t() {}
                @EXTERN_NAME@_input_t(_LV<1> _stateful_valid,
                                      _LV<BITMASK_WIDTH> _memory_bitmask,
                                      _LV<PKT_LEN_WIDTH> _pkt_len)
                {
                    stateful_valid = _stateful_valid;
                    memory_bitmask = _memory_bitmask;
                    pkt_len = _pkt_len;
                }
            };
            struct @EXTERN_NAME@_output_t {
                static const size_t _SIZE = BITMASK_WIDTH;
                _LV<BITMASK_WIDTH> memory_bitmask;

                @EXTERN_NAME@_output_t& operator=(_LV<BITMASK_WIDTH> _x) {
                    memory_bitmask = _x.slice(BITMASK_WIDTH, 0);
                    return *this;
                }

                _LV<BITMASK_WIDTH> get_LV() {
                    return (memory_bitmask);
                }

                operator _LV<BITMASK_WIDTH>() {
                    return get_LV();
                }

                std::string to_string() const {
                    return "(\n\t\tmemory_bitmask = " + memory_bitmask.to_string() + "\n\t)";
                }

                @EXTERN_NAME@_output_t() {}
                @EXTERN_NAME@_output_t( _LV<BITMASK_WIDTH> _memory_bitmask) {
                    memory_bitmask = _memory_bitmask;
                }
            };

            // engine members
            std::string _name;
            @EXTERN_NAME@_input_t @EXTERN_NAME@_input;
            @EXTERN_NAME@_output_t @EXTERN_NAME@_output;

            // engine ctor
            @MODULE_NAME@(std::string _n, std::string _filename = "") : _name(_n) {
                // TODO: **********************************
                // TODO: *** USER ENGINE INITIALIZATION ***
                // TODO: **********************************
            }

            // engine function
            void operator()() {
                @EXTERN_NAME@_output = 0;
                std::cout << "===================================================================" << std::endl
                          << "Entering engine " << _name << std::endl
                          << "initial input and inout tuples:" << std::endl
                          << "@EXTERN_NAME@_input = " << @EXTERN_NAME@_input.to_string() << std::endl
                          << "clear internal and output-only tuples" << std::endl
                          << "@EXTERN_NAME@_output = " << @EXTERN_NAME@_output.to_string() << std::endl;

                // TODO: *********************************
                // TODO: *** USER ENGINE FUNCTIONALITY ***
                // TODO: *********************************

                std::cout << "final inout and output tuples:" << std::endl
                          << "@EXTERN_NAME@_output = " << @EXTERN_NAME@_output.to_string() << std::endl
                          << "Exiting engine " << _name << std::endl
                          << "===================================================================" << std::endl;
            }
    };

    extern "C" void @MODULE_NAME@_DPI(const char*, int, const char*, int, int, int);
} // namespace SDNET

#endif // SDNET_ENGINE_@MODULE_NAME@
