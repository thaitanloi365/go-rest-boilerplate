package db

import (
	"context"
	"time"

	"go.uber.org/zap"
	"gorm.io/gorm/logger"
)

// Logger is an alternative implementation of *gorm.Logger
type Logger struct {
	zap           *zap.Logger
	LogLevel      logger.LogLevel
	SlowThreshold time.Duration
}

// NewLogger new logger
func NewLogger(zapLogger *zap.Logger) Logger {
	return Logger{
		zap:           zapLogger,
		LogLevel:      logger.Warn,
		SlowThreshold: 100 * time.Millisecond,
	}
}

// LogMode log mode
func (l Logger) LogMode(level logger.LogLevel) logger.Interface {
	return Logger{
		zap:           l.zap,
		SlowThreshold: l.SlowThreshold,
		LogLevel:      level,
	}
}

// Info print info
func (l Logger) Info(ctx context.Context, msg string, data ...interface{}) {
	// if l.LogLevel >= logger.Info {
	l.zap.Sugar().Infof(msg, data...)
	// }
}

// Warn print warn messages
func (l Logger) Warn(ctx context.Context, msg string, data ...interface{}) {
	// if l.LogLevel >= logger.Warn {
	l.zap.Sugar().Warnf(msg, data...)
	// }
}

// Error print error messages
func (l Logger) Error(ctx context.Context, msg string, data ...interface{}) {
	// if l.LogLevel >= logger.Error {
	l.zap.Sugar().Errorf(msg, data...)
	// }
}

// Trace print sql message
func (l Logger) Trace(ctx context.Context, begin time.Time, fc func() (string, int64), err error) {
	// if l.LogLevel > logger.Silent {
	elapsed := time.Since(begin)
	switch {
	case err != nil && l.LogLevel >= logger.Error:
		sql, rows := fc()
		l.zap.Error("trace", zap.Error(err), zap.Duration("elapsed", elapsed), zap.Int64("rows", rows), zap.String("sql", sql))
	case l.SlowThreshold != 0 && elapsed > l.SlowThreshold && l.LogLevel >= logger.Warn:
		sql, rows := fc()
		l.zap.Warn("trace", zap.Duration("elapsed", elapsed), zap.Int64("rows", rows), zap.String("sql", sql))
	case l.LogLevel >= logger.Info:
		sql, rows := fc()
		l.zap.Debug("trace", zap.Duration("elapsed", elapsed), zap.Int64("rows", rows), zap.String("sql", sql))
	}
	// }
}
