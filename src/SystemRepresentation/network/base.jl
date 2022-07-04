"Types of optimization"
abstract type Method end
abstract type dc_opf <: Method end
abstract type ac_opf <: Method end
abstract type ac_bf_opf <: Method end
abstract type dc_pf <: Method end
abstract type ac_pf <: Method end
abstract type dc_opf_lc <: Method end
abstract type ac_opf_lc <: Method end