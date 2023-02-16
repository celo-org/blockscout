Application.ensure_all_started(:mox)
Mox.defmock(EventStream.Publisher.Mock, for: EventStream.Publisher)

ExUnit.start()

