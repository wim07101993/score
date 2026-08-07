package bootstrap

import (
	"context"
	"sync"
)

type DependencyWithCleanup[T any] struct {
	Dependency T
	Cleanup    func() error
}

type Provider[T any] interface {
	Provide(ctx context.Context) (T, error)
}

type Scoper[T any] interface {
	NewScope() Provider[T]
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
		s.hasComputed = true
	}

	return s.value, nil
}

type ScopedLazySingleton[T any] struct {
	LazySingleton[T]
}

func NewScopedLazySingleton[T any](factory ProviderFunc[T]) *ScopedLazySingleton[T] {
	return &ScopedLazySingleton[T]{
		*NewLazySingleton(factory),
	}
}

func (s *ScopedLazySingleton[T]) Provide(ctx context.Context) (T, error) {
	return s.LazySingleton.Provide(ctx)
}

func (s *ScopedLazySingleton[T]) NewScope() Provider[T] {
	return NewScopedLazySingleton(s.factory)
}

var _ Scoper[int] = (*ScopedLazySingleton[int])(nil)

func ScopeProvider[T any](provider Provider[T]) Provider[T] {
	if scoper, ok := provider.(Scoper[T]); ok {
		return scoper.NewScope()
	}
	return provider
}
