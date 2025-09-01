library signalr_ultra;

export 'src/core/domain/entities/connection_state.dart';
export 'src/core/domain/repositories/connection_repository.dart';
export 'src/core/domain/interfaces/transport_interface.dart';
export 'src/core/domain/interfaces/protocol_interface.dart';
export 'src/core/domain/interfaces/retry_interface.dart';
export 'src/core/domain/interfaces/observability_interface.dart';

export 'src/signalr_client.dart';

export 'src/builders/connection_builder.dart';
export 'src/builders/signalr_builder.dart';
export 'src/builders/transport_builder.dart';

// Export JsonProtocol from signalr_builder.dart
export 'src/builders/signalr_builder.dart' show JsonProtocol;

export 'src/utils/connection_pool.dart';
export 'src/utils/auto_healing.dart';

export 'src/core/logging/signalr_logger.dart';

export 'src/transport/websocket_transport.dart';
export 'src/transport/sse_transport.dart';
export 'src/transport/long_polling_transport.dart';
