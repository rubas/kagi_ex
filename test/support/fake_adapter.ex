defmodule Kagi.FakeAdapter do
  @moduledoc """
  Module adapter that answers a request from a function held by the test process.

  `Req` 0.7 dropped the function adapter, so a test double must be a module.
  The function lives in the process dictionary of the test process, and `Req`
  runs the adapter in that same process, so `async: true` stays safe.

  `Kagi.FakeAdapter.Override` is a second slot. A test that needs two different
  adapters at once uses it for the second one.
  """

  @type responder :: (Req.Request.t() -> {Req.Request.t(), Req.Response.t() | Exception.t()})

  @doc "Stores `fun` in the slot `module` and returns `module`."
  @spec put(module(), responder()) :: module()
  def put(module, fun) when is_atom(module) and is_function(fun, 1) do
    Process.put(module, fun)
    module
  end

  @doc false
  @spec run(Req.Request.t()) :: {Req.Request.t(), Req.Response.t() | Exception.t()}
  def run(%Req.Request{} = request), do: dispatch(__MODULE__, request)

  @doc false
  @spec dispatch(module(), Req.Request.t()) ::
          {Req.Request.t(), Req.Response.t() | Exception.t()}
  def dispatch(module, %Req.Request{} = request),
    do: module |> Process.get() |> then(& &1.(request))
end

defmodule Kagi.FakeAdapter.Override do
  @moduledoc false

  alias Kagi.FakeAdapter

  @doc false
  @spec run(Req.Request.t()) :: {Req.Request.t(), Req.Response.t() | Exception.t()}
  def run(%Req.Request{} = request), do: FakeAdapter.dispatch(__MODULE__, request)
end
