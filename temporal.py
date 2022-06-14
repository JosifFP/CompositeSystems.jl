import numpy as np
def _rng_interpreter(rng):
    """
    Helper function that interprets `rng`.

    A number of cases can be distinguished for the input rng:
        - None: use the (legacy) global numpy rng
        - np.random.RandomState (legacy RNG) object: use it as is
        - np.random.Generator (new RNG) object: use it as is
        - np.SeedSequence object: use it to seed the RNG
        - seed value: use it to seed the RNG
    """
    if rng is None:
        return np.random.random.__self__
    elif isinstance(rng, np.random.RandomState):
        return rng
    else:
        return np.random.default_rng(rng)