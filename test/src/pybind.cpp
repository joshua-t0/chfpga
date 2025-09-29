#include <unordered_map>
#include <algorithm>
#include <optional>
#include <iostream>

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

#define FMT_HEADER_ONLY
#include <fmt/format.h>

#include "xsi_loader.h"

namespace py = pybind11;
using namespace std;

enum class SLV : char { U, X, ZERO, ONE, Z, W, L, H, DASH };
enum class PortDirection {INPUT, OUTPUT, INOUT};
enum class Language {VHDL, VERILOG};

class XSI {
	public:
		XSI(
				const std::string design_so,
				const std::string simengine_so="libxv_simulator_kernel.so",
				const std::optional<std::string> tracefile=std::nullopt,
				const std::optional<std::string> logfile=std::nullopt)
			:
				design_so(design_so),
				simengine_so(simengine_so)
		{
			s_xsi_setup_info info{};

			loader = std::make_unique<Xsi::Loader>(design_so, simengine_so);
			if(!loader)
				throw std::runtime_error("Unable to create simulator kernel!");

			this->tracefile = tracefile.value_or("");
			info.wdbFileName = (char *)this->tracefile.c_str();

			this->logfile = logfile.value_or("");
			info.logFileName = (char *)this->logfile.c_str();

			loader->open(&info);

			if(tracefile)
				loader->trace_all();

			/* Keep a local mapping from port name (which we care about)
			 * to a tuple specifying (port index, length). */
			for(int i=0; i<loader->num_ports(); i++) {
				int length = loader->get_int_port(i, xsiHDLValueSize);
				std::string port = loader->get_str_port(i, xsiNameTopPort);
				PortDirection d;

				switch(loader->get_int_port(i, xsiDirectionTopPort)) {
					case xsiInputPort: d = PortDirection::INPUT; break;
					case xsiOutputPort: d = PortDirection::OUTPUT; break;
					case xsiInoutPort: d = PortDirection::INOUT; break;
					default: throw runtime_error(fmt::format("Unexpected port direction for '{}'.", port));
				}

				port_map[port] = std::make_tuple(i, length, d);
			}

			/* Initialize all input ports to 0 */
			for(const auto& [port, entry] : port_map) {
				const auto& [id, length, direction] = entry;
				if(direction == PortDirection::INPUT)
					set_port_value(port, std::string(length, '0'));
			}
		}

		virtual ~XSI() = default;

		void restart() {
			loader->restart();
		}

		const int get_status() {
			return loader->get_status();
		}

		const std::string get_error_info() {
			return loader->get_error_info();
		}

		void run(int const& duration) {
			loader->run(duration);
		}

		const int get_port_count() const {
			return loader->num_ports();
		}

		const std::string get_port_name(int index) const {
			return loader->get_str_port(index, xsiNameTopPort);
		}

		const std::string get_port_value(std::string const& port_name) {
			auto const& [port, length, direction] = port_map.at(port_name);
			std::string s(length, '0');

			loader->get_value(port, s.data());
			/* Transform into a string we can sanely deal with */
			std::transform(std::begin(s), std::end(s), std::begin(s), [](auto const& ch) {
				switch(static_cast<SLV>(ch)) {
					case SLV::ZERO: return '0';
					case SLV::ONE: return '1';
					case SLV::U: return 'U';
					case SLV::X: return 'X';
					case SLV::Z: return 'Z';
					case SLV::W: return 'W';
					case SLV::L: return 'L';
					case SLV::H: return 'H';
					case SLV::DASH: return '-';
					default: throw std::runtime_error("Unexpected logic value!");
				}});
			return s;
		}

		void set_port_value(std::string const& port_name, std::string value) {
			auto const& [port, length, direction] = port_map.at(port_name);

			if(length != value.length())
				throw std::invalid_argument("Length of vector didn't match length of port!");

			std::transform(std::begin(value), std::end(value), std::begin(value), [](auto const& ch) {
			switch(ch) {
				case '0': return static_cast<char>(SLV::ZERO);
				case '1': return static_cast<char>(SLV::ONE);
				case 'U': return static_cast<char>(SLV::U);
				case 'X': return static_cast<char>(SLV::X);
				case 'Z': return static_cast<char>(SLV::Z);
				case 'W': return static_cast<char>(SLV::W);
				case 'L': return static_cast<char>(SLV::L);
				case 'H': return static_cast<char>(SLV::H);
				case '-': return static_cast<char>(SLV::DASH);
				default: throw std::runtime_error("Unexpected logic value!");
			}});
			loader->put_value(port, value.data());
		}

	private:
		std::unique_ptr<Xsi::Loader> loader;

		const std::string design_so;
		const std::string simengine_so;
		std::string tracefile;
		std::string logfile;

		/* (id, length, direction) tuple */
		std::unordered_map<std::string, std::tuple<int, size_t, PortDirection>> port_map;
};

PYBIND11_MODULE(pyxsi, m) {
	py::class_<XSI>(m, "XSI")
		.def(py::init<std::string const&, std::string const&, std::optional<std::string> const&, std::optional<std::string> const&>(),
				py::arg("design_so"),
				py::arg("simengine_so")=SIMENGINE_SO, /* see Makefile */
				py::arg("tracefile")=std::nullopt,
				py::arg("logfile")=std::nullopt)

		.def("get_port_value", &XSI::get_port_value)
		.def("set_port_value", &XSI::set_port_value)
		.def("get_port_count", &XSI::get_port_count)
		.def("get_port_name", &XSI::get_port_name)
		.def("restart", &XSI::restart)
		.def("get_status", &XSI::get_status)
		.def("get_error_info", &XSI::get_error_info)
		.def("run", &XSI::run, py::arg("duration")=0);
}

