package bootstrap

import (
	"context"
	"errors"
	"sync"
)

type DependencyWithCleanup[T any] struct {
	Dependency T
	Cleanup    func() error
}

type CleanupFunc func() error

func (c CleanupFunc) Append(f CleanupFunc) CleanupFunc {
	if c == nil {
		return f
	}
	return func() error {
		return errors.Join(c(), f())
	}
}

type Provider[T any] interface {
	Provide(ctx context.Context) (T, error)
}

type ProviderFunc[T any] = func(ctx context.Context) (T, error)

type Factory[T any] struct {
	f ProviderFunc[T]
}

func NewFactory[T any](f ProviderFunc[T]) *Factory[T] {
	return &Factory[T]{f: f}
}

func (f *Factory[T]) Provide(ctx context.Context) (T, error) {
	return f.f(ctx)
}

type Singleton[T any] struct {
	value T
}

func NewSingleton[T any](value T) *Singleton[T] {
	return &Singleton[T]{value: value}
}

func (s *Singleton[T]) Provide(ctx context.Context) (T, error) {
	return s.value, nil
}

type LazySingleton[T any] struct {
	mutex       sync.Mutex
	hasComputed bool
	value       T
	factory     ProviderFunc[T]
}

func NewLazySingleton[T any](factory ProviderFunc[T]) *LazySingleton[T] {
	return &LazySingleton[T]{
		factory: factory,
	}
}

func (s *LazySingleton[T]) Provide(ctx context.Context) (_ T, err error) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	if !s.hasComputed {
		if s.value, err = s.factory(ctx); err != nil {
			return *new(T), err
		}
	}

	return s.value, nil
}
